//! Small allocation-free procedural sound-effect mixer.
//!
//! Gameplay queues one-shot voices on the main thread, then `mix` feeds Sokol
//! Audio's push queue. Keeping both operations on one thread avoids locks and
//! makes the same effects available in native and WebAssembly builds without
//! shipping or decoding external audio assets.

const std = @import("std");

pub const Event = enum {
    player_step,
    hunter_step,
    gunshot,
    bullet_impact,
    hunter_hit,
    hunter_knockdown,
    box_break,
    pickup,
    heal,
    reload_start,
    reload_complete,
    punch,
    body_fall,
    door_open,
};

const voice_capacity = 32;
const tau: f32 = std.math.pi * 2.0;

const Voice = struct {
    active: bool = false,
    event: Event = .player_step,
    frame: u32 = 0,
    frame_count: u32 = 1,
    variation: f32 = 0,
    gain: f32 = 1,
    seed: u32 = 1,
};

pub const System = struct {
    sample_rate: f32 = 44_100,
    voices: [voice_capacity]Voice = @splat(.{}),
    sequence: u32 = 0x6d2b_79f5,

    pub fn reset(self: *System, sample_rate: f32) void {
        self.* = .{ .sample_rate = @max(sample_rate, 8_000) };
    }

    pub fn play(self: *System, event: Event) void {
        self.playVolume(event, 1);
    }

    pub fn playVolume(self: *System, event: Event, gain: f32) void {
        if (gain <= 0) return;
        var chosen: *Voice = &self.voices[0];
        for (&self.voices) |*voice| {
            if (!voice.active) {
                chosen = voice;
                break;
            }
            // If every slot is occupied, replace the voice nearest its end.
            if (voice.frame * chosen.frame_count > chosen.frame * voice.frame_count) chosen = voice;
        }

        self.sequence = hash(self.sequence +% 0x9e37_79b9);
        const signed = @as(f32, @floatFromInt(self.sequence & 0xffff)) / 32767.5 - 1.0;
        chosen.* = .{
            .active = true,
            .event = event,
            .frame_count = @max(1, @as(u32, @intFromFloat(duration(event) * self.sample_rate))),
            .variation = signed,
            .gain = std.math.clamp(gain, 0, 1),
            .seed = self.sequence,
        };
    }

    /// Fill interleaved output samples and advance every active one-shot.
    pub fn mix(self: *System, output: []f32, frame_count: usize, channel_count: usize) void {
        std.debug.assert(channel_count > 0);
        std.debug.assert(output.len >= frame_count * channel_count);
        @memset(output[0 .. frame_count * channel_count], 0);

        for (0..frame_count) |frame_index| {
            var sample: f32 = 0;
            for (&self.voices) |*voice| {
                if (!voice.active) continue;
                sample += voiceSample(voice.*, self.sample_rate) * voice.gain;
                voice.frame += 1;
                if (voice.frame >= voice.frame_count) voice.active = false;
            }
            // A soft-ish master limiter leaves headroom when several effects
            // coincide without flattening quieter footsteps.
            sample = std.math.clamp(sample * 0.72, -0.96, 0.96);
            for (0..channel_count) |channel| output[frame_index * channel_count + channel] = sample;
        }
    }

    pub fn activeVoiceCount(self: System) usize {
        var count: usize = 0;
        for (self.voices) |voice| count += @intFromBool(voice.active);
        return count;
    }
};

fn duration(event: Event) f32 {
    return switch (event) {
        .player_step => 0.14,
        .hunter_step => 0.24,
        .gunshot => 0.34,
        .bullet_impact => 0.13,
        .hunter_hit => 0.20,
        .hunter_knockdown => 0.42,
        .box_break => 0.52,
        .pickup => 0.24,
        .heal => 0.86,
        .reload_start => 0.18,
        .reload_complete => 0.28,
        .punch => 0.30,
        .body_fall => 0.34,
        .door_open => 0.62,
    };
}

fn voiceSample(voice: Voice, sample_rate: f32) f32 {
    const time = @as(f32, @floatFromInt(voice.frame)) / sample_rate;
    const progress = @as(f32, @floatFromInt(voice.frame)) / @as(f32, @floatFromInt(voice.frame_count));
    const tail = 1.0 - progress;
    const noise = sampleNoise(voice.seed, voice.frame);
    const pitch = 1.0 + voice.variation * 0.055;

    return switch (voice.event) {
        .player_step => blk: {
            const thump = @sin(tau * (105.0 * pitch) * time) * tail * tail;
            const sole = noise * tail * tail * tail;
            break :blk (thump * 0.16 + sole * 0.09) * fastAttack(progress, 0.06);
        },
        .hunter_step => blk: {
            const thump = @sin(tau * (54.0 * pitch) * time) * tail * tail;
            const heel = @sin(tau * 92.0 * time) * tail * tail * tail;
            break :blk (thump * 0.30 + heel * 0.11 + noise * 0.07 * tail) * fastAttack(progress, 0.035);
        },
        .gunshot => blk: {
            const crack = if (time < 0.018) (1.0 - time / 0.018) * noise else 0;
            const blast = noise * tail * tail * tail;
            const body = @sin(tau * (92.0 - 42.0 * progress) * time) * tail * tail;
            break :blk crack * 0.82 + blast * 0.58 + body * 0.38;
        },
        .bullet_impact => (noise * 0.35 + @sin(tau * 170.0 * time) * 0.16) * tail * tail * tail,
        .hunter_hit => (noise * 0.20 + @sin(tau * 72.0 * time) * 0.23) * tail * tail,
        .hunter_knockdown => blk: {
            const impact = (noise * 0.26 + @sin(tau * 48.0 * time) * 0.34) * tail * tail;
            const secondary = pulse(time, 0.17, 0.065) * (@sin(tau * 43.0 * time) * 0.24 + noise * 0.12);
            break :blk impact + secondary;
        },
        .box_break => blk: {
            const crack_a = pulse(time, 0.015, 0.040);
            const crack_b = pulse(time, 0.095, 0.055);
            const crack_c = pulse(time, 0.205, 0.080);
            const wood = noise * (crack_a * 0.62 + crack_b * 0.40 + crack_c * 0.24);
            const body = @sin(tau * 68.0 * time) * tail * tail * 0.24;
            break :blk wood + body;
        },
        .pickup => blk: {
            const phase = tau * (620.0 * time + 520.0 * time * time);
            break :blk @sin(phase) * @sin(std.math.pi * progress) * 0.20;
        },
        .heal => blk: {
            const fade = @sin(std.math.pi * progress);
            // A soft spray transient followed by a rising two-note shimmer
            // makes consuming the first-aid item distinct from picking it up.
            const spray = noise * pulse(time, 0.16, 0.18) * 0.12;
            const tone_a = @sin(tau * (420.0 * time + 85.0 * time * time));
            const tone_b = @sin(tau * (630.0 * time + 145.0 * time * time));
            break :blk spray + (tone_a * 0.14 + tone_b * 0.11) * fade;
        },
        .reload_start => blk: {
            const click = pulse(time, 0.012, 0.016);
            break :blk (noise * 0.20 + @sin(tau * 920.0 * time) * 0.10) * click;
        },
        .reload_complete => blk: {
            const click_a = pulse(time, 0.015, 0.018);
            const click_b = pulse(time, 0.135, 0.025);
            break :blk (noise * 0.18 + @sin(tau * 760.0 * time) * 0.12) * (click_a + click_b * 0.8);
        },
        .punch => (noise * 0.30 + @sin(tau * 61.0 * time) * 0.38) * tail * tail * fastAttack(progress, 0.025),
        .body_fall => blk: {
            const thud = @sin(tau * 46.0 * time) * tail * tail * 0.34;
            const scrape = noise * tail * tail * 0.16;
            break :blk (thud + scrape) * fastAttack(progress, 0.04);
        },
        .door_open => blk: {
            // A short latch click followed by a pitched wooden hinge creak.
            const latch = pulse(time, 0.025, 0.022) * (noise * 0.22 + @sin(tau * 720.0 * time) * 0.12);
            const creak_envelope = @sin(std.math.pi * progress);
            const creak = (@sin(tau * (118.0 - 46.0 * progress) * time) * 0.12 + noise * 0.075) * creak_envelope;
            const stop = pulse(time, 0.54, 0.055) * @sin(tau * 62.0 * time) * 0.16;
            break :blk latch + creak + stop;
        },
    };
}

fn fastAttack(progress: f32, fraction: f32) f32 {
    return std.math.clamp(progress / fraction, 0, 1);
}

fn pulse(time: f32, center: f32, half_width: f32) f32 {
    return std.math.clamp(1.0 - @abs(time - center) / half_width, 0, 1);
}

fn sampleNoise(seed: u32, frame: u32) f32 {
    const value = hash(seed ^ (frame *% 0x45d9_f3b));
    return @as(f32, @floatFromInt(value & 0xffff)) / 32767.5 - 1.0;
}

fn hash(input: u32) u32 {
    var value = input;
    value ^= value >> 16;
    value *%= 0x7feb_352d;
    value ^= value >> 15;
    value *%= 0x846c_a68b;
    value ^= value >> 16;
    return value;
}

test "one-shot mixer produces sound then retires its voice" {
    var system: System = .{};
    system.play(.gunshot);
    try std.testing.expectEqual(@as(usize, 1), system.activeVoiceCount());

    var samples: [512 * 2]f32 = undefined;
    var heard_sound = false;
    while (system.activeVoiceCount() > 0) {
        system.mix(&samples, 512, 2);
        for (samples) |sample| heard_sound = heard_sound or @abs(sample) > 0.0001;
    }
    try std.testing.expect(heard_sound);
    try std.testing.expectEqual(@as(usize, 0), system.activeVoiceCount());
}

test "mixer duplicates mono effects into stereo without clipping" {
    var system: System = .{};
    for (0..40) |_| system.play(.box_break);
    var samples: [128 * 2]f32 = undefined;
    system.mix(&samples, 128, 2);
    for (0..128) |frame| {
        try std.testing.expectEqual(samples[frame * 2], samples[frame * 2 + 1]);
        try std.testing.expect(@abs(samples[frame * 2]) <= 0.96);
    }
}
