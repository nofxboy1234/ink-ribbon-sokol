const __root = @This();
pub const __builtin = @import("std").zig.c_translation.builtins;
pub const __helpers = @import("std").zig.c_translation.helpers;
pub const __u_char = u8;
pub const __u_short = c_ushort;
pub const __u_int = c_uint;
pub const __u_long = c_ulong;
pub const __int8_t = i8;
pub const __uint8_t = u8;
pub const __int16_t = c_short;
pub const __uint16_t = c_ushort;
pub const __int32_t = c_int;
pub const __uint32_t = c_uint;
pub const __int64_t = c_long;
pub const __uint64_t = c_ulong;
pub const __int_least8_t = __int8_t;
pub const __uint_least8_t = __uint8_t;
pub const __int_least16_t = __int16_t;
pub const __uint_least16_t = __uint16_t;
pub const __int_least32_t = __int32_t;
pub const __uint_least32_t = __uint32_t;
pub const __int_least64_t = __int64_t;
pub const __uint_least64_t = __uint64_t;
pub const __quad_t = c_long;
pub const __u_quad_t = c_ulong;
pub const __intmax_t = c_long;
pub const __uintmax_t = c_ulong;
pub const __dev_t = c_ulong;
pub const __uid_t = c_uint;
pub const __gid_t = c_uint;
pub const __ino_t = c_ulong;
pub const __ino64_t = c_ulong;
pub const __mode_t = c_uint;
pub const __nlink_t = c_ulong;
pub const __off_t = c_long;
pub const __off64_t = c_long;
pub const __pid_t = c_int;
pub const __fsid_t = extern struct {
    __val: [2]c_int = @import("std").mem.zeroes([2]c_int),
};
pub const __clock_t = c_long;
pub const __rlim_t = c_ulong;
pub const __rlim64_t = c_ulong;
pub const __id_t = c_uint;
pub const __time_t = c_long;
pub const __useconds_t = c_uint;
pub const __suseconds_t = c_long;
pub const __suseconds64_t = c_long;
pub const __daddr_t = c_int;
pub const __key_t = c_int;
pub const __clockid_t = c_int;
pub const __timer_t = ?*anyopaque;
pub const __blksize_t = c_long;
pub const __blkcnt_t = c_long;
pub const __blkcnt64_t = c_long;
pub const __fsblkcnt_t = c_ulong;
pub const __fsblkcnt64_t = c_ulong;
pub const __fsfilcnt_t = c_ulong;
pub const __fsfilcnt64_t = c_ulong;
pub const __fsword_t = c_long;
pub const __ssize_t = c_long;
pub const __syscall_slong_t = c_long;
pub const __syscall_ulong_t = c_ulong;
pub const __loff_t = __off64_t;
pub const __caddr_t = [*c]u8;
pub const __intptr_t = c_long;
pub const __socklen_t = c_uint;
pub const __sig_atomic_t = c_int;
pub const int_least8_t = __int_least8_t;
pub const int_least16_t = __int_least16_t;
pub const int_least32_t = __int_least32_t;
pub const int_least64_t = __int_least64_t;
pub const uint_least8_t = __uint_least8_t;
pub const uint_least16_t = __uint_least16_t;
pub const uint_least32_t = __uint_least32_t;
pub const uint_least64_t = __uint_least64_t;
pub const int_fast8_t = i8;
pub const int_fast16_t = c_long;
pub const int_fast32_t = c_long;
pub const int_fast64_t = c_long;
pub const uint_fast8_t = u8;
pub const uint_fast16_t = c_ulong;
pub const uint_fast32_t = c_ulong;
pub const uint_fast64_t = c_ulong;
pub const intmax_t = __intmax_t;
pub const uintmax_t = __uintmax_t;
/// Prototype for user allocation function.
/// @param size the allocation size in bytes
/// @param alignment the required alignment, guaranteed to be a power of 2
pub const b3AllocFcn = fn (size: i32, alignment: i32) callconv(.c) ?*anyopaque;
/// Prototype for user free function.
/// @param mem the memory previously allocated through `b3AllocFcn`
pub const b3FreeFcn = fn (mem: ?*anyopaque) callconv(.c) void;
/// Prototype for the user assert callback. Return 0 to skip the debugger break.
pub const b3AssertFcn = fn (condition: [*c]const u8, fileName: [*c]const u8, lineNumber: c_int) callconv(.c) c_int;
/// Prototype for user log callback. Used to log warnings.
pub const b3LogFcn = fn (message: [*c]const u8) callconv(.c) void;
/// This allows the user to override the allocation functions. These should be
/// set during application startup.
pub extern fn b3SetAllocator(allocFcn: ?*const b3AllocFcn, freeFcn: ?*const b3FreeFcn) void;
/// Total bytes allocated by Box3D
pub extern fn b3GetByteCount() c_int;
/// Override the default assert callback.
/// @param assertFcn a non-null assert callback
pub extern fn b3SetAssertFcn(assertFcn: ?*const b3AssertFcn) void;
/// Internal assertion handler. Allows for host intervention.
pub extern fn b3InternalAssert(condition: [*c]const u8, fileName: [*c]const u8, lineNumber: c_int) c_int;
/// Override the default logging callback.
pub extern fn b3SetLogFcn(logFcn: ?*const b3LogFcn) void;
pub const struct_b3Version = extern struct {
    /// Significant changes
    major: c_int = 0,
    /// Incremental changes
    minor: c_int = 0,
    /// Bug fixes
    revision: c_int = 0,
};
/// Version numbering scheme.
/// See https://semver.org/
pub const b3Version = struct_b3Version;
/// Get the current version of Box3D
pub extern fn b3GetVersion() b3Version;
/// @return true if the library was built with BOX3D_DOUBLE_PRECISION (large world mode)
pub extern fn b3IsDoublePrecision() bool;
/// Get the absolute number of system ticks. The value is platform specific.
pub extern fn b3GetTicks() u64;
/// Get the milliseconds passed from an initial tick value.
pub extern fn b3GetMilliseconds(ticks: u64) f32;
/// Get the milliseconds passed from an initial tick value.
pub extern fn b3GetMillisecondsAndReset(ticks: [*c]u64) f32;
/// Yield to be used in a busy loop.
pub extern fn b3Yield() void;
/// Sleep the current thread for a number of milliseconds.
pub extern fn b3Sleep(milliseconds: c_int) void;
pub extern fn b3Hash(hash: u32, data: [*c]const u8, count: c_int) u32;
pub const float_t = f32;
pub const double_t = f64;
pub extern fn __fpclassify(__value: f64) c_int;
pub extern fn __signbit(__value: f64) c_int;
pub extern fn __isinf(__value: f64) c_int;
pub extern fn __finite(__value: f64) c_int;
pub extern fn __isnan(__value: f64) c_int;
pub extern fn __iseqsig(__x: f64, __y: f64) c_int;
pub extern fn __issignaling(__value: f64) c_int;
pub extern fn acos(__x: f64) f64;
pub extern fn __acos(__x: f64) f64;
pub extern fn asin(__x: f64) f64;
pub extern fn __asin(__x: f64) f64;
pub extern fn atan(__x: f64) f64;
pub extern fn __atan(__x: f64) f64;
pub extern fn atan2(__y: f64, __x: f64) f64;
pub extern fn __atan2(__y: f64, __x: f64) f64;
pub extern fn cos(__x: f64) f64;
pub extern fn __cos(__x: f64) f64;
pub extern fn sin(__x: f64) f64;
pub extern fn __sin(__x: f64) f64;
pub extern fn tan(__x: f64) f64;
pub extern fn __tan(__x: f64) f64;
pub extern fn cosh(__x: f64) f64;
pub extern fn __cosh(__x: f64) f64;
pub extern fn sinh(__x: f64) f64;
pub extern fn __sinh(__x: f64) f64;
pub extern fn tanh(__x: f64) f64;
pub extern fn __tanh(__x: f64) f64;
pub extern fn acosh(__x: f64) f64;
pub extern fn __acosh(__x: f64) f64;
pub extern fn asinh(__x: f64) f64;
pub extern fn __asinh(__x: f64) f64;
pub extern fn atanh(__x: f64) f64;
pub extern fn __atanh(__x: f64) f64;
pub extern fn exp(__x: f64) f64;
pub extern fn __exp(__x: f64) f64;
pub extern fn frexp(__x: f64, __exponent: [*c]c_int) f64;
pub extern fn __frexp(__x: f64, __exponent: [*c]c_int) f64;
pub extern fn ldexp(__x: f64, __exponent: c_int) f64;
pub extern fn __ldexp(__x: f64, __exponent: c_int) f64;
pub extern fn log(__x: f64) f64;
pub extern fn __log(__x: f64) f64;
pub extern fn log10(__x: f64) f64;
pub extern fn __log10(__x: f64) f64;
pub extern fn modf(__x: f64, __iptr: [*c]f64) f64;
pub extern fn __modf(__x: f64, __iptr: [*c]f64) f64;
pub extern fn expm1(__x: f64) f64;
pub extern fn __expm1(__x: f64) f64;
pub extern fn log1p(__x: f64) f64;
pub extern fn __log1p(__x: f64) f64;
pub extern fn logb(__x: f64) f64;
pub extern fn __logb(__x: f64) f64;
pub extern fn exp2(__x: f64) f64;
pub extern fn __exp2(__x: f64) f64;
pub extern fn log2(__x: f64) f64;
pub extern fn __log2(__x: f64) f64;
pub extern fn pow(__x: f64, __y: f64) f64;
pub extern fn __pow(__x: f64, __y: f64) f64;
pub extern fn sqrt(__x: f64) f64;
pub extern fn __sqrt(__x: f64) f64;
pub extern fn hypot(__x: f64, __y: f64) f64;
pub extern fn __hypot(__x: f64, __y: f64) f64;
pub extern fn cbrt(__x: f64) f64;
pub extern fn __cbrt(__x: f64) f64;
pub extern fn ceil(__x: f64) f64;
pub extern fn fabs(__x: f64) f64;
pub extern fn floor(__x: f64) f64;
pub extern fn fmod(__x: f64, __y: f64) f64;
pub extern fn __fmod(__x: f64, __y: f64) f64;
pub extern fn isinf(__value: f64) c_int;
pub extern fn finite(__value: f64) c_int;
pub extern fn drem(__x: f64, __y: f64) f64;
pub extern fn __drem(__x: f64, __y: f64) f64;
pub extern fn significand(__x: f64) f64;
pub extern fn __significand(__x: f64) f64;
pub extern fn copysign(__x: f64, __y: f64) f64;
pub extern fn nan(__tagb: [*c]const u8) f64;
pub extern fn __nan(__tagb: [*c]const u8) f64;
pub extern fn isnan(__value: f64) c_int;
pub extern fn j0(f64) f64;
pub extern fn __j0(f64) f64;
pub extern fn j1(f64) f64;
pub extern fn __j1(f64) f64;
pub extern fn jn(c_int, f64) f64;
pub extern fn __jn(c_int, f64) f64;
pub extern fn y0(f64) f64;
pub extern fn __y0(f64) f64;
pub extern fn y1(f64) f64;
pub extern fn __y1(f64) f64;
pub extern fn yn(c_int, f64) f64;
pub extern fn __yn(c_int, f64) f64;
pub extern fn erf(f64) f64;
pub extern fn __erf(f64) f64;
pub extern fn erfc(f64) f64;
pub extern fn __erfc(f64) f64;
pub extern fn lgamma(f64) f64;
pub extern fn __lgamma(f64) f64;
pub extern fn tgamma(f64) f64;
pub extern fn __tgamma(f64) f64;
pub extern fn gamma(f64) f64;
pub extern fn __gamma(f64) f64;
pub extern fn lgamma_r(f64, __signgamp: [*c]c_int) f64;
pub extern fn __lgamma_r(f64, __signgamp: [*c]c_int) f64;
pub extern fn rint(__x: f64) f64;
pub extern fn __rint(__x: f64) f64;
pub extern fn nextafter(__x: f64, __y: f64) f64;
pub extern fn __nextafter(__x: f64, __y: f64) f64;
pub extern fn nexttoward(__x: f64, __y: c_longdouble) f64;
pub extern fn __nexttoward(__x: f64, __y: c_longdouble) f64;
pub extern fn remainder(__x: f64, __y: f64) f64;
pub extern fn __remainder(__x: f64, __y: f64) f64;
pub extern fn scalbn(__x: f64, __n: c_int) f64;
pub extern fn __scalbn(__x: f64, __n: c_int) f64;
pub extern fn ilogb(__x: f64) c_int;
pub extern fn __ilogb(__x: f64) c_int;
pub extern fn scalbln(__x: f64, __n: c_long) f64;
pub extern fn __scalbln(__x: f64, __n: c_long) f64;
pub extern fn nearbyint(__x: f64) f64;
pub extern fn __nearbyint(__x: f64) f64;
pub extern fn round(__x: f64) f64;
pub extern fn trunc(__x: f64) f64;
pub extern fn remquo(__x: f64, __y: f64, __quo: [*c]c_int) f64;
pub extern fn __remquo(__x: f64, __y: f64, __quo: [*c]c_int) f64;
pub extern fn lrint(__x: f64) c_long;
pub extern fn __lrint(__x: f64) c_long;
pub extern fn llrint(__x: f64) c_longlong;
pub extern fn __llrint(__x: f64) c_longlong;
pub extern fn lround(__x: f64) c_long;
pub extern fn __lround(__x: f64) c_long;
pub extern fn llround(__x: f64) c_longlong;
pub extern fn __llround(__x: f64) c_longlong;
pub extern fn fdim(__x: f64, __y: f64) f64;
pub extern fn __fdim(__x: f64, __y: f64) f64;
pub extern fn fmax(__x: f64, __y: f64) f64;
pub extern fn fmin(__x: f64, __y: f64) f64;
pub extern fn fma(__x: f64, __y: f64, __z: f64) f64;
pub extern fn __fma(__x: f64, __y: f64, __z: f64) f64;
pub extern fn scalb(__x: f64, __n: f64) f64;
pub extern fn __scalb(__x: f64, __n: f64) f64;
pub extern fn __fpclassifyf(__value: f32) c_int;
pub extern fn __signbitf(__value: f32) c_int;
pub extern fn __isinff(__value: f32) c_int;
pub extern fn __finitef(__value: f32) c_int;
pub extern fn __isnanf(__value: f32) c_int;
pub extern fn __iseqsigf(__x: f32, __y: f32) c_int;
pub extern fn __issignalingf(__value: f32) c_int;
pub extern fn acosf(__x: f32) f32;
pub extern fn __acosf(__x: f32) f32;
pub extern fn asinf(__x: f32) f32;
pub extern fn __asinf(__x: f32) f32;
pub extern fn atanf(__x: f32) f32;
pub extern fn __atanf(__x: f32) f32;
pub extern fn atan2f(__y: f32, __x: f32) f32;
pub extern fn __atan2f(__y: f32, __x: f32) f32;
pub extern fn cosf(__x: f32) f32;
pub extern fn __cosf(__x: f32) f32;
pub extern fn sinf(__x: f32) f32;
pub extern fn __sinf(__x: f32) f32;
pub extern fn tanf(__x: f32) f32;
pub extern fn __tanf(__x: f32) f32;
pub extern fn coshf(__x: f32) f32;
pub extern fn __coshf(__x: f32) f32;
pub extern fn sinhf(__x: f32) f32;
pub extern fn __sinhf(__x: f32) f32;
pub extern fn tanhf(__x: f32) f32;
pub extern fn __tanhf(__x: f32) f32;
pub extern fn acoshf(__x: f32) f32;
pub extern fn __acoshf(__x: f32) f32;
pub extern fn asinhf(__x: f32) f32;
pub extern fn __asinhf(__x: f32) f32;
pub extern fn atanhf(__x: f32) f32;
pub extern fn __atanhf(__x: f32) f32;
pub extern fn expf(__x: f32) f32;
pub extern fn __expf(__x: f32) f32;
pub extern fn frexpf(__x: f32, __exponent: [*c]c_int) f32;
pub extern fn __frexpf(__x: f32, __exponent: [*c]c_int) f32;
pub extern fn ldexpf(__x: f32, __exponent: c_int) f32;
pub extern fn __ldexpf(__x: f32, __exponent: c_int) f32;
pub extern fn logf(__x: f32) f32;
pub extern fn __logf(__x: f32) f32;
pub extern fn log10f(__x: f32) f32;
pub extern fn __log10f(__x: f32) f32;
pub extern fn modff(__x: f32, __iptr: [*c]f32) f32;
pub extern fn __modff(__x: f32, __iptr: [*c]f32) f32;
pub extern fn expm1f(__x: f32) f32;
pub extern fn __expm1f(__x: f32) f32;
pub extern fn log1pf(__x: f32) f32;
pub extern fn __log1pf(__x: f32) f32;
pub extern fn logbf(__x: f32) f32;
pub extern fn __logbf(__x: f32) f32;
pub extern fn exp2f(__x: f32) f32;
pub extern fn __exp2f(__x: f32) f32;
pub extern fn log2f(__x: f32) f32;
pub extern fn __log2f(__x: f32) f32;
pub extern fn powf(__x: f32, __y: f32) f32;
pub extern fn __powf(__x: f32, __y: f32) f32;
pub extern fn sqrtf(__x: f32) f32;
pub extern fn __sqrtf(__x: f32) f32;
pub extern fn hypotf(__x: f32, __y: f32) f32;
pub extern fn __hypotf(__x: f32, __y: f32) f32;
pub extern fn cbrtf(__x: f32) f32;
pub extern fn __cbrtf(__x: f32) f32;
pub extern fn ceilf(__x: f32) f32;
pub extern fn fabsf(__x: f32) f32;
pub extern fn floorf(__x: f32) f32;
pub extern fn fmodf(__x: f32, __y: f32) f32;
pub extern fn __fmodf(__x: f32, __y: f32) f32;
pub extern fn isinff(__value: f32) c_int;
pub extern fn finitef(__value: f32) c_int;
pub extern fn dremf(__x: f32, __y: f32) f32;
pub extern fn __dremf(__x: f32, __y: f32) f32;
pub extern fn significandf(__x: f32) f32;
pub extern fn __significandf(__x: f32) f32;
pub extern fn copysignf(__x: f32, __y: f32) f32;
pub extern fn nanf(__tagb: [*c]const u8) f32;
pub extern fn __nanf(__tagb: [*c]const u8) f32;
pub extern fn isnanf(__value: f32) c_int;
pub extern fn j0f(f32) f32;
pub extern fn __j0f(f32) f32;
pub extern fn j1f(f32) f32;
pub extern fn __j1f(f32) f32;
pub extern fn jnf(c_int, f32) f32;
pub extern fn __jnf(c_int, f32) f32;
pub extern fn y0f(f32) f32;
pub extern fn __y0f(f32) f32;
pub extern fn y1f(f32) f32;
pub extern fn __y1f(f32) f32;
pub extern fn ynf(c_int, f32) f32;
pub extern fn __ynf(c_int, f32) f32;
pub extern fn erff(f32) f32;
pub extern fn __erff(f32) f32;
pub extern fn erfcf(f32) f32;
pub extern fn __erfcf(f32) f32;
pub extern fn lgammaf(f32) f32;
pub extern fn __lgammaf(f32) f32;
pub extern fn tgammaf(f32) f32;
pub extern fn __tgammaf(f32) f32;
pub extern fn gammaf(f32) f32;
pub extern fn __gammaf(f32) f32;
pub extern fn lgammaf_r(f32, __signgamp: [*c]c_int) f32;
pub extern fn __lgammaf_r(f32, __signgamp: [*c]c_int) f32;
pub extern fn rintf(__x: f32) f32;
pub extern fn __rintf(__x: f32) f32;
pub extern fn nextafterf(__x: f32, __y: f32) f32;
pub extern fn __nextafterf(__x: f32, __y: f32) f32;
pub extern fn nexttowardf(__x: f32, __y: c_longdouble) f32;
pub extern fn __nexttowardf(__x: f32, __y: c_longdouble) f32;
pub extern fn remainderf(__x: f32, __y: f32) f32;
pub extern fn __remainderf(__x: f32, __y: f32) f32;
pub extern fn scalbnf(__x: f32, __n: c_int) f32;
pub extern fn __scalbnf(__x: f32, __n: c_int) f32;
pub extern fn ilogbf(__x: f32) c_int;
pub extern fn __ilogbf(__x: f32) c_int;
pub extern fn scalblnf(__x: f32, __n: c_long) f32;
pub extern fn __scalblnf(__x: f32, __n: c_long) f32;
pub extern fn nearbyintf(__x: f32) f32;
pub extern fn __nearbyintf(__x: f32) f32;
pub extern fn roundf(__x: f32) f32;
pub extern fn truncf(__x: f32) f32;
pub extern fn remquof(__x: f32, __y: f32, __quo: [*c]c_int) f32;
pub extern fn __remquof(__x: f32, __y: f32, __quo: [*c]c_int) f32;
pub extern fn lrintf(__x: f32) c_long;
pub extern fn __lrintf(__x: f32) c_long;
pub extern fn llrintf(__x: f32) c_longlong;
pub extern fn __llrintf(__x: f32) c_longlong;
pub extern fn lroundf(__x: f32) c_long;
pub extern fn __lroundf(__x: f32) c_long;
pub extern fn llroundf(__x: f32) c_longlong;
pub extern fn __llroundf(__x: f32) c_longlong;
pub extern fn fdimf(__x: f32, __y: f32) f32;
pub extern fn __fdimf(__x: f32, __y: f32) f32;
pub extern fn fmaxf(__x: f32, __y: f32) f32;
pub extern fn fminf(__x: f32, __y: f32) f32;
pub extern fn fmaf(__x: f32, __y: f32, __z: f32) f32;
pub extern fn __fmaf(__x: f32, __y: f32, __z: f32) f32;
pub extern fn scalbf(__x: f32, __n: f32) f32;
pub extern fn __scalbf(__x: f32, __n: f32) f32;
pub extern fn __fpclassifyl(__value: c_longdouble) c_int;
pub extern fn __signbitl(__value: c_longdouble) c_int;
pub extern fn __isinfl(__value: c_longdouble) c_int;
pub extern fn __finitel(__value: c_longdouble) c_int;
pub extern fn __isnanl(__value: c_longdouble) c_int;
pub extern fn __iseqsigl(__x: c_longdouble, __y: c_longdouble) c_int;
pub extern fn __issignalingl(__value: c_longdouble) c_int;
pub extern fn acosl(__x: c_longdouble) c_longdouble;
pub extern fn __acosl(__x: c_longdouble) c_longdouble;
pub extern fn asinl(__x: c_longdouble) c_longdouble;
pub extern fn __asinl(__x: c_longdouble) c_longdouble;
pub extern fn atanl(__x: c_longdouble) c_longdouble;
pub extern fn __atanl(__x: c_longdouble) c_longdouble;
pub extern fn atan2l(__y: c_longdouble, __x: c_longdouble) c_longdouble;
pub extern fn __atan2l(__y: c_longdouble, __x: c_longdouble) c_longdouble;
pub extern fn cosl(__x: c_longdouble) c_longdouble;
pub extern fn __cosl(__x: c_longdouble) c_longdouble;
pub extern fn sinl(__x: c_longdouble) c_longdouble;
pub extern fn __sinl(__x: c_longdouble) c_longdouble;
pub extern fn tanl(__x: c_longdouble) c_longdouble;
pub extern fn __tanl(__x: c_longdouble) c_longdouble;
pub extern fn coshl(__x: c_longdouble) c_longdouble;
pub extern fn __coshl(__x: c_longdouble) c_longdouble;
pub extern fn sinhl(__x: c_longdouble) c_longdouble;
pub extern fn __sinhl(__x: c_longdouble) c_longdouble;
pub extern fn tanhl(__x: c_longdouble) c_longdouble;
pub extern fn __tanhl(__x: c_longdouble) c_longdouble;
pub extern fn acoshl(__x: c_longdouble) c_longdouble;
pub extern fn __acoshl(__x: c_longdouble) c_longdouble;
pub extern fn asinhl(__x: c_longdouble) c_longdouble;
pub extern fn __asinhl(__x: c_longdouble) c_longdouble;
pub extern fn atanhl(__x: c_longdouble) c_longdouble;
pub extern fn __atanhl(__x: c_longdouble) c_longdouble;
pub extern fn expl(__x: c_longdouble) c_longdouble;
pub extern fn __expl(__x: c_longdouble) c_longdouble;
pub extern fn frexpl(__x: c_longdouble, __exponent: [*c]c_int) c_longdouble;
pub extern fn __frexpl(__x: c_longdouble, __exponent: [*c]c_int) c_longdouble;
pub extern fn ldexpl(__x: c_longdouble, __exponent: c_int) c_longdouble;
pub extern fn __ldexpl(__x: c_longdouble, __exponent: c_int) c_longdouble;
pub extern fn logl(__x: c_longdouble) c_longdouble;
pub extern fn __logl(__x: c_longdouble) c_longdouble;
pub extern fn log10l(__x: c_longdouble) c_longdouble;
pub extern fn __log10l(__x: c_longdouble) c_longdouble;
pub extern fn modfl(__x: c_longdouble, __iptr: [*c]c_longdouble) c_longdouble;
pub extern fn __modfl(__x: c_longdouble, __iptr: [*c]c_longdouble) c_longdouble;
pub extern fn expm1l(__x: c_longdouble) c_longdouble;
pub extern fn __expm1l(__x: c_longdouble) c_longdouble;
pub extern fn log1pl(__x: c_longdouble) c_longdouble;
pub extern fn __log1pl(__x: c_longdouble) c_longdouble;
pub extern fn logbl(__x: c_longdouble) c_longdouble;
pub extern fn __logbl(__x: c_longdouble) c_longdouble;
pub extern fn exp2l(__x: c_longdouble) c_longdouble;
pub extern fn __exp2l(__x: c_longdouble) c_longdouble;
pub extern fn log2l(__x: c_longdouble) c_longdouble;
pub extern fn __log2l(__x: c_longdouble) c_longdouble;
pub extern fn powl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __powl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn sqrtl(__x: c_longdouble) c_longdouble;
pub extern fn __sqrtl(__x: c_longdouble) c_longdouble;
pub extern fn hypotl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __hypotl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn cbrtl(__x: c_longdouble) c_longdouble;
pub extern fn __cbrtl(__x: c_longdouble) c_longdouble;
pub extern fn ceill(__x: c_longdouble) c_longdouble;
pub extern fn fabsl(__x: c_longdouble) c_longdouble;
pub extern fn floorl(__x: c_longdouble) c_longdouble;
pub extern fn fmodl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __fmodl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn isinfl(__value: c_longdouble) c_int;
pub extern fn finitel(__value: c_longdouble) c_int;
pub extern fn dreml(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __dreml(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn significandl(__x: c_longdouble) c_longdouble;
pub extern fn __significandl(__x: c_longdouble) c_longdouble;
pub extern fn copysignl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn nanl(__tagb: [*c]const u8) c_longdouble;
pub extern fn __nanl(__tagb: [*c]const u8) c_longdouble;
pub extern fn isnanl(__value: c_longdouble) c_int;
pub extern fn j0l(c_longdouble) c_longdouble;
pub extern fn __j0l(c_longdouble) c_longdouble;
pub extern fn j1l(c_longdouble) c_longdouble;
pub extern fn __j1l(c_longdouble) c_longdouble;
pub extern fn jnl(c_int, c_longdouble) c_longdouble;
pub extern fn __jnl(c_int, c_longdouble) c_longdouble;
pub extern fn y0l(c_longdouble) c_longdouble;
pub extern fn __y0l(c_longdouble) c_longdouble;
pub extern fn y1l(c_longdouble) c_longdouble;
pub extern fn __y1l(c_longdouble) c_longdouble;
pub extern fn ynl(c_int, c_longdouble) c_longdouble;
pub extern fn __ynl(c_int, c_longdouble) c_longdouble;
pub extern fn erfl(c_longdouble) c_longdouble;
pub extern fn __erfl(c_longdouble) c_longdouble;
pub extern fn erfcl(c_longdouble) c_longdouble;
pub extern fn __erfcl(c_longdouble) c_longdouble;
pub extern fn lgammal(c_longdouble) c_longdouble;
pub extern fn __lgammal(c_longdouble) c_longdouble;
pub extern fn tgammal(c_longdouble) c_longdouble;
pub extern fn __tgammal(c_longdouble) c_longdouble;
pub extern fn gammal(c_longdouble) c_longdouble;
pub extern fn __gammal(c_longdouble) c_longdouble;
pub extern fn lgammal_r(c_longdouble, __signgamp: [*c]c_int) c_longdouble;
pub extern fn __lgammal_r(c_longdouble, __signgamp: [*c]c_int) c_longdouble;
pub extern fn rintl(__x: c_longdouble) c_longdouble;
pub extern fn __rintl(__x: c_longdouble) c_longdouble;
pub extern fn nextafterl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __nextafterl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn nexttowardl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __nexttowardl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn remainderl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __remainderl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn scalbnl(__x: c_longdouble, __n: c_int) c_longdouble;
pub extern fn __scalbnl(__x: c_longdouble, __n: c_int) c_longdouble;
pub extern fn ilogbl(__x: c_longdouble) c_int;
pub extern fn __ilogbl(__x: c_longdouble) c_int;
pub extern fn scalblnl(__x: c_longdouble, __n: c_long) c_longdouble;
pub extern fn __scalblnl(__x: c_longdouble, __n: c_long) c_longdouble;
pub extern fn nearbyintl(__x: c_longdouble) c_longdouble;
pub extern fn __nearbyintl(__x: c_longdouble) c_longdouble;
pub extern fn roundl(__x: c_longdouble) c_longdouble;
pub extern fn truncl(__x: c_longdouble) c_longdouble;
pub extern fn remquol(__x: c_longdouble, __y: c_longdouble, __quo: [*c]c_int) c_longdouble;
pub extern fn __remquol(__x: c_longdouble, __y: c_longdouble, __quo: [*c]c_int) c_longdouble;
pub extern fn lrintl(__x: c_longdouble) c_long;
pub extern fn __lrintl(__x: c_longdouble) c_long;
pub extern fn llrintl(__x: c_longdouble) c_longlong;
pub extern fn __llrintl(__x: c_longdouble) c_longlong;
pub extern fn lroundl(__x: c_longdouble) c_long;
pub extern fn __lroundl(__x: c_longdouble) c_long;
pub extern fn llroundl(__x: c_longdouble) c_longlong;
pub extern fn __llroundl(__x: c_longdouble) c_longlong;
pub extern fn fdiml(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn __fdiml(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn fmaxl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn fminl(__x: c_longdouble, __y: c_longdouble) c_longdouble;
pub extern fn fmal(__x: c_longdouble, __y: c_longdouble, __z: c_longdouble) c_longdouble;
pub extern fn __fmal(__x: c_longdouble, __y: c_longdouble, __z: c_longdouble) c_longdouble;
pub extern fn scalbl(__x: c_longdouble, __n: c_longdouble) c_longdouble;
pub extern fn __scalbl(__x: c_longdouble, __n: c_longdouble) c_longdouble;
pub extern fn __fpclassifyf128(__value: f128) c_int;
pub extern fn __signbitf128(__value: f128) c_int;
pub extern fn __isinff128(__value: f128) c_int;
pub extern fn __finitef128(__value: f128) c_int;
pub extern fn __isnanf128(__value: f128) c_int;
pub extern fn __iseqsigf128(__x: f128, __y: f128) c_int;
pub extern fn __issignalingf128(__value: f128) c_int;
pub extern var signgam: c_int;
pub const FP_NAN: c_int = 0;
pub const FP_INFINITE: c_int = 1;
pub const FP_ZERO: c_int = 2;
pub const FP_SUBNORMAL: c_int = 3;
pub const FP_NORMAL: c_int = 4;
const enum_unnamed_1 = c_uint;
pub const struct_b3Vec2 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
};
/// A 2D vector.
pub const b3Vec2 = struct_b3Vec2;
pub const struct_b3Vec3 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    /// Vector addition.
    pub const b3Add = __root.b3Add;
    /// Vector subtraction.
    pub const b3Sub = __root.b3Sub;
    /// Vector component-wise multiplication.
    pub const b3Mul = __root.b3Mul;
    /// Vector negation.
    pub const b3Neg = __root.b3Neg;
    /// Vector dot product.
    pub const b3Dot = __root.b3Dot;
    /// Vector length.
    pub const b3Length = __root.b3Length;
    /// Vector length squared.
    pub const b3LengthSquared = __root.b3LengthSquared;
    /// Distance between two points.
    pub const b3Distance = __root.b3Distance;
    /// Squared distance between two points.
    pub const b3DistanceSquared = __root.b3DistanceSquared;
    /// Normalize a vector. Returns a zero vector if the input vector is very small.
    pub const b3Normalize = __root.b3Normalize;
    /// Get a unit vector that is perpendicular to the supplied vector.
    pub const b3Perp = __root.b3Perp;
    /// Is a vector normalized? In other words, does it have unit length?
    pub const b3IsNormalized = __root.b3IsNormalized;
    /// a + s * b
    pub const b3MulAdd = __root.b3MulAdd;
    /// a - s * b
    pub const b3MulSub = __root.b3MulSub;
    /// https://en.wikipedia.org/wiki/Cross_product
    pub const b3Cross = __root.b3Cross;
    /// Linearly interpolate between two vectors.
    pub const b3Lerp = __root.b3Lerp;
    /// Component-wise absolute value.
    pub const b3Abs = __root.b3Abs;
    /// Component-wise -1 or 1 (1 if zero).
    pub const b3Sign = __root.b3Sign;
    /// Component-wise minimum value.
    pub const b3Min = __root.b3Min;
    /// Component-wise maximum value.
    pub const b3Max = __root.b3Max;
    /// Component-wise clamped value.
    pub const b3Clamp = __root.b3Clamp;
    /// Create a safe scaling value for scaling collision. This allows
    /// negative scale, but keeps scale sufficiently far from zero.
    pub const b3SafeScale = __root.b3SafeScale;
    /// Make a quaternion that is equivalent to rotating around an axis by a specified angle.
    pub const b3MakeQuatFromAxisAngle = __root.b3MakeQuatFromAxisAngle;
    /// Find a quaternion that rotates one vector to another.
    pub const b3ComputeQuatBetweenUnitVectors = __root.b3ComputeQuatBetweenUnitVectors;
    /// Convert a vector to a world position.
    pub const b3ToPos = __root.b3ToPos;
    /// Lossy conversion of a world position to a float vector.
    pub const b3ToVec3 = __root.b3ToVec3;
    /// a - b, demoted to float. The primary precision boundary operation.
    pub const b3SubPos = __root.b3SubPos;
    /// p + d
    pub const b3OffsetPos = __root.b3OffsetPos;
    /// World position interpolation for sweeps and sampling.
    pub const b3LerpPosition = __root.b3LerpPosition;
    /// Get the AABB of a point cloud.
    pub const b3MakeAABB = __root.b3MakeAABB;
    /// Get the closest point on an axis-aligned bounding box.
    pub const b3ClosestPointToAABB = __root.b3ClosestPointToAABB;
    /// Compute the closest point on the segment a-b to the target q.
    pub const b3PointToSegmentDistance = __root.b3PointToSegmentDistance;
    /// Compute the closest points on two infinite lines.
    pub const b3LineDistance = __root.b3LineDistance;
    /// Compute the closest points on two line segments.
    pub const b3SegmentDistance = __root.b3SegmentDistance;
    /// Is this a valid vector? Not NaN or infinity.
    pub const b3IsValidVec3 = __root.b3IsValidVec3;
    /// Is this a valid world position? Not NaN or infinity.
    pub const b3IsValidPosition = __root.b3IsValidPosition;
    /// Create a generic convex hull.
    pub const b3CreateHull = __root.b3CreateHull;
    /// This makes a transformed box hull with post scaling. This is useful for boxes that are scaled in
    /// a level editor. Such scaling can have reflection and shear. In the case of shear the result
    /// may be approximate. If you need to support shear consider using b3CreateHull.
    /// Do not call b3DestroyHull on this.
    /// @param halfWidths positive half widths
    /// @param transform local transform of box
    /// @param postScale scale applied after the transform, may be negative
    pub const b3MakeScaledBoxHull = __root.b3MakeScaledBoxHull;
    /// This takes a box with a transform and post scale and converts it into a box with the post scale
    /// resolved with new half-widths and transform. This accepts non-uniform and negative scale.
    /// This is approximate if there is shear.
    /// @param halfWidths [in/out] the box half widths
    /// @param transform [in/out] the box transform with rotation and translation
    /// @param postScale the post scale being applied to the box after the transform
    /// @param minHalfWidth the minimum half width after scale is applied
    pub const b3ScaleBox = __root.b3ScaleBox;
    /// Create a box mesh.
    pub const b3CreateBoxMesh = __root.b3CreateBoxMesh;
    /// Create a hollow box mesh.
    pub const b3CreateHollowBoxMesh = __root.b3CreateHollowBoxMesh;
    /// Create a platform mesh. A truncated pyramid.
    pub const b3CreatePlatformMesh = __root.b3CreatePlatformMesh;
    /// Solves the position of a mover that satisfies the given collision planes.
    /// @param targetDelta the desired translation from the position used to generate the collision planes
    /// @param planes the collision planes
    /// @param count the number of collision planes
    pub const b3SolvePlanes = __root.b3SolvePlanes;
    /// Clips the velocity against the given collision planes. Planes with zero push or clipVelocity
    /// set to false are skipped.
    pub const b3ClipVector = __root.b3ClipVector;
};
/// A 3D vector.
pub const b3Vec3 = struct_b3Vec3;
pub const struct_b3CosSin = extern struct {
    /// cosine and sine
    cosine: f32 = 0,
    sine: f32 = 0,
};
/// Cosine and sine pair.
/// This uses a custom implementation designed for cross-platform determinism.
pub const b3CosSin = struct_b3CosSin;
pub const struct_b3Quat = extern struct {
    v: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    s: f32 = 0,
    /// Does the supplied quaternion have unit length?
    pub const b3IsNormalizedQuat = __root.b3IsNormalizedQuat;
    /// Rotate a vector.
    pub const b3RotateVector = __root.b3RotateVector;
    /// Inverse rotate a vector.
    pub const b3InvRotateVector = __root.b3InvRotateVector;
    /// Compute dot product of two quaternions. Useful for polarity tests.
    pub const b3DotQuat = __root.b3DotQuat;
    /// Multiply two quaternions.
    pub const b3MulQuat = __root.b3MulQuat;
    /// Compute a relative quaternion.
    /// inv(q1) * q2
    pub const b3InvMulQuat = __root.b3InvMulQuat;
    /// Quaternion conjugate (cheap inverse).
    pub const b3Conjugate = __root.b3Conjugate;
    /// Component-wise quaternion negation.
    pub const b3NegateQuat = __root.b3NegateQuat;
    /// Normalize a quaternion.
    pub const b3NormalizeQuat = __root.b3NormalizeQuat;
    /// Get the angle for a quaternion in radians
    pub const b3GetQuatAngle = __root.b3GetQuatAngle;
    /// Twist angle around the z-axis, used for twist limit and revolute angle limit
    pub const b3GetTwistAngle = __root.b3GetTwistAngle;
    /// Swing angle used for cone limit
    pub const b3GetSwingAngle = __root.b3GetSwingAngle;
    /// Linearly interpolate and normalize between two quaternions
    pub const b3NLerp = __root.b3NLerp;
    /// Make a matrix from a quaternion. This is useful if you need to
    /// rotate many vectors.
    /// The force inline improves the performance of b3ShapeDistance.
    pub const b3MakeMatrixFromQuat = __root.b3MakeMatrixFromQuat;
    /// Is this a valid quaternion? Not NaN or infinity. Is normalized.
    pub const b3IsValidQuat = __root.b3IsValidQuat;
};
/// A quaternion.
pub const b3Quat = struct_b3Quat;
pub const struct_b3Transform = extern struct {
    p: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    q: b3Quat = @import("std").mem.zeroes(b3Quat),
    /// Multiply two transforms. If the result is applied to a point p local to frame B,
    /// the transform would first convert p to a point local to frame A, then into a point
    /// in the world frame. This is useful if frame B is a child of frame A.
    pub const b3MulTransforms = __root.b3MulTransforms;
    /// Creates a transform that converts a local point in frame B to a local point in frame A.
    /// This is useful for transforming points between the local spaces of two frames that are
    /// in world space.
    pub const b3InvMulTransforms = __root.b3InvMulTransforms;
    /// Get the inverse of a transform.
    pub const b3InvertTransform = __root.b3InvertTransform;
    /// Transform a point.
    pub const b3TransformPoint = __root.b3TransformPoint;
    /// Inverse transform a point.
    pub const b3InvTransformPoint = __root.b3InvTransformPoint;
    /// Transform a local point to a world position. Rotation in float, translation in double.
    pub const b3TransformWorldPoint = __root.b3TransformWorldPoint;
    /// Transform a world position to a local point. One double subtraction, then float.
    pub const b3InvTransformWorldPoint = __root.b3InvTransformWorldPoint;
    /// Relative transform of frame B in frame A. The narrow phase boundary.
    pub const b3InvMulWorldTransforms = __root.b3InvMulWorldTransforms;
    /// Compose a world transform with a local transform.
    pub const b3MulWorldTransforms = __root.b3MulWorldTransforms;
    /// Shift a world transform into the frame of a base position.
    pub const b3ToRelativeTransform = __root.b3ToRelativeTransform;
    /// Promote a float transform to a world transform. Lossless.
    pub const b3MakeWorldTransform = __root.b3MakeWorldTransform;
    /// Transform an axis-aligned bounding box. This can create a larger box
    /// than if you recomputed the AABB of the original shape with the transform
    /// applied.
    pub const b3AABB_Transform = __root.b3AABB_Transform;
    /// Is this a valid transform? Not NaN or infinity. Is normalized.
    pub const b3IsValidTransform = __root.b3IsValidTransform;
    /// Is this a valid world transform? Not NaN or infinity. Rotation is normalized.
    pub const b3IsValidWorldTransform = __root.b3IsValidWorldTransform;
    pub const Transform = __root.b3AABB_Transform;
};
/// A rigid transform.
pub const b3Transform = struct_b3Transform;
/// A world position. Double precision in large world mode so coordinates stay accurate far
/// from the origin.
pub const b3Pos = b3Vec3;
/// A world transform with double precision translation and float quaternion rotation. Rotation
/// is frame local and never needs the extra range, the same split as Jolt's DMat44.
pub const b3WorldTransform = b3Transform;
pub const struct_b3Matrix3 = extern struct {
    cx: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    cy: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    cz: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Extract a quaternion from a rotation matrix.
    pub const b3MakeQuatFromMatrix = __root.b3MakeQuatFromMatrix;
    /// Compute the determinant of a 3-by-3 matrix.
    pub const b3Det = __root.b3Det;
    /// Multiply a matrix times a column vector.
    pub const b3MulMV = __root.b3MulMV;
    /// Negate a matrix.
    pub const b3NegateMat3 = __root.b3NegateMat3;
    /// Matrix addition.
    /// @return a + b
    pub const b3AddMM = __root.b3AddMM;
    /// Matrix subtraction.
    /// @return a - b
    pub const b3SubMM = __root.b3SubMM;
    /// Matrix multiplication.
    /// @return a * b
    pub const b3MulMM = __root.b3MulMM;
    /// Matrix transpose.
    pub const b3Transpose = __root.b3Transpose;
    /// General matrix inverse.
    pub const b3InvertMatrix = __root.b3InvertMatrix;
    /// Solve a matrix equation.
    /// @return inv(m) * a
    pub const b3Solve3 = __root.b3Solve3;
    /// Invert a matrix.
    pub const b3InvertT = __root.b3InvertT;
    /// Get the component-wise absolute value of a matrix.
    pub const b3AbsMatrix3 = __root.b3AbsMatrix3;
    /// Is this a valid matrix? Not NaN or infinity.
    pub const b3IsValidMatrix3 = __root.b3IsValidMatrix3;
};
/// A 3x3 matrix.
pub const b3Matrix3 = struct_b3Matrix3;
pub const struct_b3AABB = extern struct {
    lowerBound: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    upperBound: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Translate a local AABB by a world origin, rounding outward so the float box always contains
    /// the double box. Far from the origin a plain conversion could clip a shape out of its own box.
    /// In float mode the origin is float and the rounding is a no-op.
    pub const b3OffsetAABB = __root.b3OffsetAABB;
    /// Does a fully contain b?
    pub const b3AABB_Contains = __root.b3AABB_Contains;
    /// Get the surface area of an axis-aligned bounding box.
    pub const b3AABB_Area = __root.b3AABB_Area;
    /// Get the center of an axis-aligned bounding box.
    pub const b3AABB_Center = __root.b3AABB_Center;
    /// Get the extents (half-widths) of an axis-aligned bounding box.
    pub const b3AABB_Extents = __root.b3AABB_Extents;
    /// Get the union of two axis-aligned bounding boxes.
    pub const b3AABB_Union = __root.b3AABB_Union;
    /// Add uniform padding to an axis-aligned bounding box.
    pub const b3AABB_Inflate = __root.b3AABB_Inflate;
    /// Do two axis-aligned boxes overlap?
    pub const b3AABB_Overlaps = __root.b3AABB_Overlaps;
    /// Is this a valid bounding box? Not Nan or infinity. Upper bound greater than or equal to lower bound.
    pub const b3IsValidAABB = __root.b3IsValidAABB;
    /// Is this AABB reasonably close to the origin? See B3_HUGE.
    pub const b3IsBoundedAABB = __root.b3IsBoundedAABB;
    /// Is this AABB valid and reasonable?
    pub const b3IsSaneAABB = __root.b3IsSaneAABB;
    pub const Contains = __root.b3AABB_Contains;
    pub const Area = __root.b3AABB_Area;
    pub const Center = __root.b3AABB_Center;
    pub const Extents = __root.b3AABB_Extents;
    pub const Union = __root.b3AABB_Union;
    pub const Inflate = __root.b3AABB_Inflate;
    pub const Overlaps = __root.b3AABB_Overlaps;
};
/// Axis aligned bounding box.
pub const b3AABB = struct_b3AABB;
pub const struct_b3Plane = extern struct {
    normal: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    offset: f32 = 0,
    /// Is this a valid plane? Normal is a unit vector. Not Nan or infinity.
    pub const b3IsValidPlane = __root.b3IsValidPlane;
};
/// A plane.
/// separation = dot(normal, point) - offset
pub const b3Plane = struct_b3Plane;
pub const b3Vec3_zero: b3Vec3 = b3Vec3{
    .x = 0.0,
    .y = 0.0,
    .z = 0.0,
};
pub const b3Vec3_one: b3Vec3 = b3Vec3{
    .x = 1.0,
    .y = 1.0,
    .z = 1.0,
};
pub const b3Vec3_axisX: b3Vec3 = b3Vec3{
    .x = 1.0,
    .y = 0.0,
    .z = 0.0,
};
pub const b3Vec3_axisY: b3Vec3 = b3Vec3{
    .x = 0.0,
    .y = 1.0,
    .z = 0.0,
};
pub const b3Vec3_axisZ: b3Vec3 = b3Vec3{
    .x = 0.0,
    .y = 0.0,
    .z = 1.0,
};
pub const b3Quat_identity: b3Quat = b3Quat{
    .v = b3Vec3{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
    },
    .s = 1.0,
};
pub const b3Transform_identity: b3Transform = b3Transform{
    .p = b3Vec3{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
    },
    .q = b3Quat{
        .v = b3Vec3{
            .x = 0.0,
            .y = 0.0,
            .z = 0.0,
        },
        .s = 1.0,
    },
};
pub const b3Mat3_zero: b3Matrix3 = b3Matrix3{
    .cx = b3Vec3{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
    },
    .cy = b3Vec3{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
    },
    .cz = b3Vec3{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
    },
};
pub const b3Mat3_identity: b3Matrix3 = b3Matrix3{
    .cx = b3Vec3{
        .x = 1.0,
        .y = 0.0,
        .z = 0.0,
    },
    .cy = b3Vec3{
        .x = 0.0,
        .y = 1.0,
        .z = 0.0,
    },
    .cz = b3Vec3{
        .x = 0.0,
        .y = 0.0,
        .z = 1.0,
    },
};
pub const b3Pos_zero: b3Pos = b3Pos{
    .x = 0.0,
    .y = 0.0,
    .z = 0.0,
};
pub const b3WorldTransform_identity: b3WorldTransform = b3WorldTransform{
    .p = b3Vec3{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
    },
    .q = b3Quat{
        .v = b3Vec3{
            .x = 0.0,
            .y = 0.0,
            .z = 0.0,
        },
        .s = 1.0,
    },
};
/// @return the minimum of two integers.
pub fn b3MinInt(arg_a: c_int, arg_b: c_int) callconv(.c) c_int {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return if (a < b) a else b;
}
/// @return the maximum of two integers.
pub fn b3MaxInt(arg_a: c_int, arg_b: c_int) callconv(.c) c_int {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return if (a > b) a else b;
}
/// @return an integer clamped between a lower and upper bound.
pub fn b3ClampInt(arg_a: c_int, arg_lower: c_int, arg_upper: c_int) callconv(.c) c_int {
    var a = arg_a;
    _ = &a;
    var lower = arg_lower;
    _ = &lower;
    var upper = arg_upper;
    _ = &upper;
    return if (a < lower) lower else if (upper < a) upper else a;
}
/// @return the absolute value of a float.
pub fn b3AbsFloat(arg_a: f32) callconv(.c) f32 {
    var a = arg_a;
    _ = &a;
    return if (a < @as(f32, @floatFromInt(@as(c_int, 0)))) -a else a;
}
/// @return the minimum of two floats.
pub fn b3MinFloat(arg_a: f32, arg_b: f32) callconv(.c) f32 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return if (a < b) a else b;
}
/// @return the maximum of two floats.
pub fn b3MaxFloat(arg_a: f32, arg_b: f32) callconv(.c) f32 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return if (a > b) a else b;
}
/// @return a float clamped between a lower and upper bound.
pub fn b3ClampFloat(arg_a: f32, arg_lower: f32, arg_upper: f32) callconv(.c) f32 {
    var a = arg_a;
    _ = &a;
    var lower = arg_lower;
    _ = &lower;
    var upper = arg_upper;
    _ = &upper;
    return if (a < lower) lower else if (upper < a) upper else a;
}
/// Interpolate a scalar.
pub fn b3LerpFloat(arg_a: f32, arg_b: f32, arg_alpha: f32) callconv(.c) f32 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var alpha = arg_alpha;
    _ = &alpha;
    return ((@as(f32, 1.0) - alpha) * a) + (alpha * b);
}
/// Compute an approximate arctangent in the range [-pi, pi]
/// This is hand coded for cross-platform determinism. The atan2f
/// function in the standard library is not cross-platform deterministic.
/// Accurate to around 0.0023 degrees.
pub extern fn b3Atan2(y: f32, x: f32) f32;
/// Compute the cosine and sine of an angle in radians. Implemented
/// for cross-platform determinism.
pub extern fn b3ComputeCosSin(radians: f32) b3CosSin;
/// @deprecated
pub fn b3Sin(arg_radians: f32) callconv(.c) f32 {
    var radians = arg_radians;
    _ = &radians;
    var cs: b3CosSin = b3ComputeCosSin(radians);
    _ = &cs;
    return cs.sine;
}
/// @deprecated
pub fn b3Cos(arg_radians: f32) callconv(.c) f32 {
    var radians = arg_radians;
    _ = &radians;
    var cs: b3CosSin = b3ComputeCosSin(radians);
    _ = &cs;
    return cs.cosine;
}
/// Convert any angle into the range [-pi, pi].
pub fn b3UnwindAngle(arg_radians: f32) callconv(.c) f32 {
    var radians = arg_radians;
    _ = &radians;
    return remainderf(radians, @as(f32, 2.0) * B3_PI);
}
/// Vector addition.
pub fn b3Add(arg_a: b3Vec3, arg_b: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return b3Vec3{
        .x = a.x + b.x,
        .y = a.y + b.y,
        .z = a.z + b.z,
    };
}
/// Vector subtraction.
pub fn b3Sub(arg_a: b3Vec3, arg_b: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return b3Vec3{
        .x = a.x - b.x,
        .y = a.y - b.y,
        .z = a.z - b.z,
    };
}
/// Vector component-wise multiplication.
pub fn b3Mul(arg_a: b3Vec3, arg_b: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return b3Vec3{
        .x = a.x * b.x,
        .y = a.y * b.y,
        .z = a.z * b.z,
    };
}
/// Vector negation.
pub fn b3Neg(arg_a: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    return b3Vec3{
        .x = -a.x,
        .y = -a.y,
        .z = -a.z,
    };
}
/// Vector dot product.
pub fn b3Dot(arg_a: b3Vec3, arg_b: b3Vec3) callconv(.c) f32 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return ((a.x * b.x) + (a.y * b.y)) + (a.z * b.z);
}
/// Vector length.
pub fn b3Length(arg_v: b3Vec3) callconv(.c) f32 {
    var v = arg_v;
    _ = &v;
    return sqrtf(b3Dot(v, v));
}
/// Vector length squared.
pub fn b3LengthSquared(arg_a: b3Vec3) callconv(.c) f32 {
    var a = arg_a;
    _ = &a;
    return ((a.x * a.x) + (a.y * a.y)) + (a.z * a.z);
}
/// Distance between two points.
pub fn b3Distance(arg_a: b3Vec3, arg_b: b3Vec3) callconv(.c) f32 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var dv: b3Vec3 = b3Vec3{
        .x = b.x - a.x,
        .y = b.y - a.y,
        .z = b.z - a.z,
    };
    _ = &dv;
    return b3Length(dv);
}
/// Squared distance between two points.
pub fn b3DistanceSquared(arg_a: b3Vec3, arg_b: b3Vec3) callconv(.c) f32 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var dv: b3Vec3 = b3Vec3{
        .x = b.x - a.x,
        .y = b.y - a.y,
        .z = b.z - a.z,
    };
    _ = &dv;
    return ((dv.x * dv.x) + (dv.y * dv.y)) + (dv.z * dv.z);
}
/// Normalize a vector. Returns a zero vector if the input vector is very small.
pub fn b3Normalize(arg_a: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var lengthSquared: f32 = ((a.x * a.x) + (a.y * a.y)) + (a.z * a.z);
    _ = &lengthSquared;
    if (lengthSquared > (@as(f32, 1000.0) * __FLT_MIN__)) {
        var s: f32 = @as(f32, 1.0) / sqrtf(lengthSquared);
        _ = &s;
        var u: b3Vec3 = b3Vec3{
            .x = s * a.x,
            .y = s * a.y,
            .z = s * a.z,
        };
        _ = &u;
        return u;
    }
    return b3Vec3{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
    };
}
/// Normalize a vector and return the length. Returns a zero vector
/// if the input is very small.
pub fn b3GetLengthAndNormalize(arg_length: [*c]f32, arg_a: b3Vec3) callconv(.c) b3Vec3 {
    var length = arg_length;
    _ = &length;
    var a = arg_a;
    _ = &a;
    length.* = b3Length(a);
    if (length.* < __FLT_EPSILON__) {
        return b3Vec3_zero;
    }
    var invLength: f32 = @as(f32, 1.0) / length.*;
    _ = &invLength;
    var n: b3Vec3 = b3Vec3{
        .x = invLength * a.x,
        .y = invLength * a.y,
        .z = invLength * a.z,
    };
    _ = &n;
    return n;
}
/// Get a unit vector that is perpendicular to the supplied vector.
pub fn b3Perp(arg_a: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var p: b3Vec3 = undefined;
    _ = &p;
    if ((a.x < -@as(f32, 0.5)) or (@as(f32, 0.5) < a.x)) {
        p = b3Vec3{
            .x = a.y,
            .y = -a.x,
            .z = 0.0,
        };
    } else {
        p = b3Vec3{
            .x = 0.0,
            .y = a.z,
            .z = -a.y,
        };
    }
    return b3Normalize(p);
}
/// Is a vector normalized? In other words, does it have unit length?
pub fn b3IsNormalized(arg_a: b3Vec3) callconv(.c) bool {
    var a = arg_a;
    _ = &a;
    var aa: f32 = b3Dot(a, a);
    _ = &aa;
    return b3AbsFloat(@as(f32, 1.0) - aa) < (@as(f32, 100.0) * __FLT_EPSILON__);
}
/// a + s * b
pub fn b3MulAdd(arg_a: b3Vec3, arg_s: f32, arg_b: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var s = arg_s;
    _ = &s;
    var b = arg_b;
    _ = &b;
    return b3Vec3{
        .x = a.x + (s * b.x),
        .y = a.y + (s * b.y),
        .z = a.z + (s * b.z),
    };
}
/// a - s * b
pub fn b3MulSub(arg_a: b3Vec3, arg_s: f32, arg_b: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var s = arg_s;
    _ = &s;
    var b = arg_b;
    _ = &b;
    return b3Vec3{
        .x = a.x - (s * b.x),
        .y = a.y - (s * b.y),
        .z = a.z - (s * b.z),
    };
}
/// s * a
pub fn b3MulSV(arg_s: f32, arg_a: b3Vec3) callconv(.c) b3Vec3 {
    var s = arg_s;
    _ = &s;
    var a = arg_a;
    _ = &a;
    return b3Vec3{
        .x = s * a.x,
        .y = s * a.y,
        .z = s * a.z,
    };
}
/// https://en.wikipedia.org/wiki/Cross_product
pub fn b3Cross(arg_a: b3Vec3, arg_b: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var c: b3Vec3 = undefined;
    _ = &c;
    c.x = (a.y * b.z) - (a.z * b.y);
    c.y = (a.z * b.x) - (a.x * b.z);
    c.z = (a.x * b.y) - (a.y * b.x);
    return c;
}
/// Linearly interpolate between two vectors.
pub fn b3Lerp(arg_a: b3Vec3, arg_b: b3Vec3, arg_alpha: f32) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var alpha = arg_alpha;
    _ = &alpha;
    _ = !!((@as(f32, 0.0) <= alpha) and (alpha <= @as(f32, 1.0))) or ((blk: {
        _ = b3InternalAssert("0.0f <= alpha && alpha <= 1.0f", "box3d/include/box3d/math_functions.h", @as(c_int, 362));
        break :blk 0;
    }) != 0);
    var c: b3Vec3 = b3Vec3{
        .x = ((@as(f32, 1.0) - alpha) * a.x) + (alpha * b.x),
        .y = ((@as(f32, 1.0) - alpha) * a.y) + (alpha * b.y),
        .z = ((@as(f32, 1.0) - alpha) * a.z) + (alpha * b.z),
    };
    _ = &c;
    return c;
}
/// Blend two vectors: s * a + t * b
pub fn b3Blend2(arg_s: f32, arg_a: b3Vec3, arg_t: f32, arg_b: b3Vec3) callconv(.c) b3Vec3 {
    var s = arg_s;
    _ = &s;
    var a = arg_a;
    _ = &a;
    var t = arg_t;
    _ = &t;
    var b = arg_b;
    _ = &b;
    var d: b3Vec3 = b3Vec3{
        .x = (s * a.x) + (t * b.x),
        .y = (s * a.y) + (t * b.y),
        .z = (s * a.z) + (t * b.z),
    };
    _ = &d;
    return d;
}
/// Component-wise absolute value.
pub fn b3Abs(arg_a: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    return b3Vec3{
        .x = b3AbsFloat(a.x),
        .y = b3AbsFloat(a.y),
        .z = b3AbsFloat(a.z),
    };
}
/// Component-wise -1 or 1 (1 if zero).
pub fn b3Sign(arg_a: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    return b3Vec3{
        .x = if (a.x >= @as(f32, 0.0)) @as(f32, 1.0) else -@as(f32, 1.0),
        .y = if (a.y >= @as(f32, 0.0)) @as(f32, 1.0) else -@as(f32, 1.0),
        .z = if (a.z >= @as(f32, 0.0)) @as(f32, 1.0) else -@as(f32, 1.0),
    };
}
/// Component-wise minimum value.
pub fn b3Min(arg_a: b3Vec3, arg_b: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return b3Vec3{
        .x = b3MinFloat(a.x, b.x),
        .y = b3MinFloat(a.y, b.y),
        .z = b3MinFloat(a.z, b.z),
    };
}
/// Component-wise maximum value.
pub fn b3Max(arg_a: b3Vec3, arg_b: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return b3Vec3{
        .x = b3MaxFloat(a.x, b.x),
        .y = b3MaxFloat(a.y, b.y),
        .z = b3MaxFloat(a.z, b.z),
    };
}
/// Component-wise clamped value.
pub fn b3Clamp(arg_a: b3Vec3, arg_lower: b3Vec3, arg_upper: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var lower = arg_lower;
    _ = &lower;
    var upper = arg_upper;
    _ = &upper;
    var b: b3Vec3 = undefined;
    _ = &b;
    b.x = b3ClampFloat(a.x, lower.x, upper.x);
    b.y = b3ClampFloat(a.y, lower.y, upper.y);
    b.z = b3ClampFloat(a.z, lower.z, upper.z);
    return b;
}
/// Create a safe scaling value for scaling collision. This allows
/// negative scale, but keeps scale sufficiently far from zero.
pub fn b3SafeScale(arg_a: b3Vec3) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var absScale: b3Vec3 = b3Abs(a);
    _ = &absScale;
    var minScale: b3Vec3 = b3Vec3{
        .x = B3_MIN_SCALE,
        .y = B3_MIN_SCALE,
        .z = B3_MIN_SCALE,
    };
    _ = &minScale;
    var safeScale: b3Vec3 = b3Mul(b3Sign(a), b3Max(absScale, minScale));
    _ = &safeScale;
    return safeScale;
}
/// Does the supplied quaternion have unit length?
pub fn b3IsNormalizedQuat(arg_q: b3Quat) callconv(.c) bool {
    var q = arg_q;
    _ = &q;
    var qq: f32 = (((q.v.x * q.v.x) + (q.v.y * q.v.y)) + (q.v.z * q.v.z)) + (q.s * q.s);
    _ = &qq;
    return ((@as(f32, 1.0) - (@as(f32, 20.0) * __FLT_EPSILON__)) < qq) and (qq < (@as(f32, 1.0) + (@as(f32, 20.0) * __FLT_EPSILON__)));
}
/// Rotate a vector.
pub fn b3RotateVector(arg_q: b3Quat, arg_v: b3Vec3) callconv(.c) b3Vec3 {
    var q = arg_q;
    _ = &q;
    var v = arg_v;
    _ = &v;
    var t1: b3Vec3 = b3Cross(q.v, v);
    _ = &t1;
    var t2: b3Vec3 = b3MulAdd(t1, q.s, v);
    _ = &t2;
    var t3: b3Vec3 = b3Cross(q.v, t2);
    _ = &t3;
    return b3MulAdd(v, 2.0, t3);
}
/// Inverse rotate a vector.
pub fn b3InvRotateVector(arg_q: b3Quat, arg_v: b3Vec3) callconv(.c) b3Vec3 {
    var q = arg_q;
    _ = &q;
    var v = arg_v;
    _ = &v;
    var t1: b3Vec3 = b3Cross(q.v, v);
    _ = &t1;
    var t2: b3Vec3 = b3MulSub(t1, q.s, v);
    _ = &t2;
    var t3: b3Vec3 = b3Cross(q.v, t2);
    _ = &t3;
    return b3MulAdd(v, 2.0, t3);
}
/// Compute dot product of two quaternions. Useful for polarity tests.
pub fn b3DotQuat(arg_a: b3Quat, arg_b: b3Quat) callconv(.c) f32 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return (((a.v.x * b.v.x) + (a.v.y * b.v.y)) + (a.v.z * b.v.z)) + (a.s * b.s);
}
/// Multiply two quaternions.
pub fn b3MulQuat(arg_q1: b3Quat, arg_q2: b3Quat) callconv(.c) b3Quat {
    var q1 = arg_q1;
    _ = &q1;
    var q2 = arg_q2;
    _ = &q2;
    var t1: b3Vec3 = b3Cross(q1.v, q2.v);
    _ = &t1;
    var t2: b3Vec3 = b3MulAdd(t1, q1.s, q2.v);
    _ = &t2;
    var t3: b3Vec3 = b3MulAdd(t2, q2.s, q1.v);
    _ = &t3;
    var q: b3Quat = b3Quat{
        .v = t3,
        .s = (q1.s * q2.s) - b3Dot(q1.v, q2.v),
    };
    _ = &q;
    return q;
}
/// Compute a relative quaternion.
/// inv(q1) * q2
pub fn b3InvMulQuat(arg_q1: b3Quat, arg_q2: b3Quat) callconv(.c) b3Quat {
    var q1 = arg_q1;
    _ = &q1;
    var q2 = arg_q2;
    _ = &q2;
    var t1: b3Vec3 = b3Cross(q2.v, q1.v);
    _ = &t1;
    var t2: b3Vec3 = b3MulAdd(t1, q1.s, q2.v);
    _ = &t2;
    var t3: b3Vec3 = b3MulSub(t2, q2.s, q1.v);
    _ = &t3;
    var q: b3Quat = b3Quat{
        .v = t3,
        .s = (q1.s * q2.s) + b3Dot(q1.v, q2.v),
    };
    _ = &q;
    return q;
}
/// Quaternion conjugate (cheap inverse).
pub fn b3Conjugate(arg_q: b3Quat) callconv(.c) b3Quat {
    var q = arg_q;
    _ = &q;
    return b3Quat{
        .v = b3Vec3{
            .x = -q.v.x,
            .y = -q.v.y,
            .z = -q.v.z,
        },
        .s = q.s,
    };
}
/// Component-wise quaternion negation.
pub fn b3NegateQuat(arg_q: b3Quat) callconv(.c) b3Quat {
    var q = arg_q;
    _ = &q;
    return b3Quat{
        .v = b3Vec3{
            .x = -q.v.x,
            .y = -q.v.y,
            .z = -q.v.z,
        },
        .s = -q.s,
    };
}
/// Normalize a quaternion.
pub fn b3NormalizeQuat(arg_q: b3Quat) callconv(.c) b3Quat {
    var q = arg_q;
    _ = &q;
    var lengthSq: f32 = b3DotQuat(q, q);
    _ = &lengthSq;
    if (lengthSq > (@as(f32, 1000.0) * __FLT_MIN__)) {
        var s: f32 = @as(f32, 1.0) / sqrtf(lengthSq);
        _ = &s;
        var qn: b3Quat = b3Quat{
            .v = b3Vec3{
                .x = s * q.v.x,
                .y = s * q.v.y,
                .z = s * q.v.z,
            },
            .s = s * q.s,
        };
        _ = &qn;
        return qn;
    }
    return b3Quat_identity;
}
/// Make a quaternion that is equivalent to rotating around an axis by a specified angle.
pub fn b3MakeQuatFromAxisAngle(arg_axis: b3Vec3, arg_radians: f32) callconv(.c) b3Quat {
    var axis = arg_axis;
    _ = &axis;
    var radians = arg_radians;
    _ = &radians;
    _ = !!b3IsNormalized(axis) or ((blk: {
        _ = b3InternalAssert("b3IsNormalized( axis )", "box3d/include/box3d/math_functions.h", @as(c_int, 528));
        break :blk 0;
    }) != 0);
    var cs: b3CosSin = b3ComputeCosSin(@as(f32, 0.5) * radians);
    _ = &cs;
    var q: b3Quat = b3Quat{
        .v = b3Vec3{
            .x = cs.sine * axis.x,
            .y = cs.sine * axis.y,
            .z = cs.sine * axis.z,
        },
        .s = cs.cosine,
    };
    _ = &q;
    return q;
}
/// Get the axis and angle from a quaternion. Assumes the quaternion is normalized.
pub fn b3GetAxisAngle(arg_radians: [*c]f32, arg_q: b3Quat) callconv(.c) b3Vec3 {
    var radians = arg_radians;
    _ = &radians;
    var q = arg_q;
    _ = &q;
    var length: f32 = sqrtf(((q.v.x * q.v.x) + (q.v.y * q.v.y)) + (q.v.z * q.v.z));
    _ = &length;
    radians.* = @as(f32, 2.0) * b3Atan2(length, q.s);
    if (length > @as(f32, 0.0)) {
        var invLength: f32 = @as(f32, 1.0) / length;
        _ = &invLength;
        var axis: b3Vec3 = b3Vec3{
            .x = invLength * q.v.x,
            .y = invLength * q.v.y,
            .z = invLength * q.v.z,
        };
        _ = &axis;
        return axis;
    }
    return b3Vec3_zero;
}
/// Get the angle for a quaternion in radians
pub fn b3GetQuatAngle(arg_q: b3Quat) callconv(.c) f32 {
    var q = arg_q;
    _ = &q;
    var length: f32 = sqrtf(((q.v.x * q.v.x) + (q.v.y * q.v.y)) + (q.v.z * q.v.z));
    _ = &length;
    return @as(f32, 2.0) * b3Atan2(length, q.s);
}
/// Extract a quaternion from a rotation matrix.
pub extern fn b3MakeQuatFromMatrix(m: [*c]const b3Matrix3) b3Quat;
/// Find a quaternion that rotates one vector to another.
pub extern fn b3ComputeQuatBetweenUnitVectors(v1: b3Vec3, v2: b3Vec3) b3Quat;
/// Twist angle around the z-axis, used for twist limit and revolute angle limit
pub fn b3GetTwistAngle(arg_q: b3Quat) callconv(.c) f32 {
    var q = arg_q;
    _ = &q;
    var twist: f32 = if (q.s < @as(f32, 0.0)) b3Atan2(-q.v.z, -q.s) else b3Atan2(q.v.z, q.s);
    _ = &twist;
    twist *= 2.0;
    _ = !!((-B3_PI <= twist) and (twist <= B3_PI)) or ((blk: {
        _ = b3InternalAssert("-B3_PI <= twist && twist <= B3_PI", "box3d/include/box3d/math_functions.h", @as(c_int, 569));
        break :blk 0;
    }) != 0);
    return twist;
}
/// Swing angle used for cone limit
pub fn b3GetSwingAngle(arg_q: b3Quat) callconv(.c) f32 {
    var q = arg_q;
    _ = &q;
    var x: f32 = sqrtf((q.v.z * q.v.z) + (q.s * q.s));
    _ = &x;
    var y: f32 = sqrtf((q.v.x * q.v.x) + (q.v.y * q.v.y));
    _ = &y;
    var swing: f32 = @as(f32, 2.0) * b3Atan2(y, x);
    _ = &swing;
    _ = !!((@as(f32, 0.0) <= swing) and (swing <= B3_PI)) or ((blk: {
        _ = b3InternalAssert("0.0f <= swing && swing <= B3_PI", "box3d/include/box3d/math_functions.h", @as(c_int, 580));
        break :blk 0;
    }) != 0);
    return swing;
}
/// Linearly interpolate and normalize between two quaternions
pub fn b3NLerp(arg_q1: b3Quat, arg_q2: b3Quat, arg_alpha: f32) callconv(.c) b3Quat {
    var q1 = arg_q1;
    _ = &q1;
    var q2 = arg_q2;
    _ = &q2;
    var alpha = arg_alpha;
    _ = &alpha;
    _ = @as(c_int, 0);
    if (b3DotQuat(q1, q2) < @as(f32, 0.0)) {
        q1 = b3Quat{
            .v = b3Vec3{
                .x = -q1.v.x,
                .y = -q1.v.y,
                .z = -q1.v.z,
            },
            .s = -q1.s,
        };
    }
    var q: b3Quat = undefined;
    _ = &q;
    q.v = b3Lerp(q1.v, q2.v, alpha);
    q.s = ((@as(f32, 1.0) - alpha) * q1.s) + (alpha * q2.s);
    return b3NormalizeQuat(q);
}
/// Multiply two transforms. If the result is applied to a point p local to frame B,
/// the transform would first convert p to a point local to frame A, then into a point
/// in the world frame. This is useful if frame B is a child of frame A.
pub fn b3MulTransforms(arg_a: b3Transform, arg_b: b3Transform) callconv(.c) b3Transform {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var out: b3Transform = undefined;
    _ = &out;
    out.p = b3Add(b3RotateVector(a.q, b.p), a.p);
    out.q = b3MulQuat(a.q, b.q);
    return out;
}
/// Creates a transform that converts a local point in frame B to a local point in frame A.
/// This is useful for transforming points between the local spaces of two frames that are
/// in world space.
pub inline fn b3InvMulTransforms(arg_a: b3Transform, arg_b: b3Transform) b3Transform {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var out: b3Transform = undefined;
    _ = &out;
    out.p = b3InvRotateVector(a.q, b3Sub(b.p, a.p));
    out.q = b3InvMulQuat(a.q, b.q);
    return out;
}
/// Get the inverse of a transform.
pub fn b3InvertTransform(arg_t: b3Transform) callconv(.c) b3Transform {
    var t = arg_t;
    _ = &t;
    var out: b3Transform = undefined;
    _ = &out;
    out.p = b3InvRotateVector(t.q, b3Neg(t.p));
    out.q = b3Conjugate(t.q);
    return out;
}
/// Transform a point.
pub fn b3TransformPoint(arg_t: b3Transform, arg_v: b3Vec3) callconv(.c) b3Vec3 {
    var t = arg_t;
    _ = &t;
    var v = arg_v;
    _ = &v;
    var rv: b3Vec3 = b3RotateVector(t.q, v);
    _ = &rv;
    return b3Add(rv, t.p);
}
/// Inverse transform a point.
pub fn b3InvTransformPoint(arg_t: b3Transform, arg_v: b3Vec3) callconv(.c) b3Vec3 {
    var t = arg_t;
    _ = &t;
    var v = arg_v;
    _ = &v;
    return b3InvRotateVector(t.q, b3Sub(v, t.p));
}
/// Convert a vector to a world position.
pub fn b3ToPos(arg_v: b3Vec3) callconv(.c) b3Pos {
    var v = arg_v;
    _ = &v;
    return b3Pos{
        .x = v.x,
        .y = v.y,
        .z = v.z,
    };
}
/// Lossy conversion of a world position to a float vector.
pub fn b3ToVec3(arg_p: b3Pos) callconv(.c) b3Vec3 {
    var p = arg_p;
    _ = &p;
    return b3Vec3{
        .x = p.x,
        .y = p.y,
        .z = p.z,
    };
}
/// Narrow a world coordinate to float, rounding toward negative infinity. Use with
/// b3RoundUpFloat to build a conservative float box that always contains the double bounds,
/// where plain rounding far from the origin could clip. nextafterf is an exact IEEE operation,
/// so this is cross-platform deterministic. With large world mode off this is a plain conversion.
pub fn b3RoundDownFloat(arg_x: f64) callconv(.c) f32 {
    var x = arg_x;
    _ = &x;
    return @floatCast(x);
}
/// Narrow a world coordinate to float, rounding toward positive infinity.
pub fn b3RoundUpFloat(arg_x: f64) callconv(.c) f32 {
    var x = arg_x;
    _ = &x;
    return @floatCast(x);
}
/// a - b, demoted to float. The primary precision boundary operation.
pub fn b3SubPos(arg_a: b3Pos, arg_b: b3Pos) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return b3Vec3{
        .x = a.x - b.x,
        .y = a.y - b.y,
        .z = a.z - b.z,
    };
}
/// p + d
pub fn b3OffsetPos(arg_p: b3Pos, arg_d: b3Vec3) callconv(.c) b3Pos {
    var p = arg_p;
    _ = &p;
    var d = arg_d;
    _ = &d;
    return b3Pos{
        .x = p.x + d.x,
        .y = p.y + d.y,
        .z = p.z + d.z,
    };
}
/// World position interpolation for sweeps and sampling.
pub fn b3LerpPosition(arg_a: b3Pos, arg_b: b3Pos, arg_t: f32) callconv(.c) b3Pos {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var t = arg_t;
    _ = &t;
    return b3Pos{
        .x = ((@as(f32, 1.0) - t) * a.x) + (t * b.x),
        .y = ((@as(f32, 1.0) - t) * a.y) + (t * b.y),
        .z = ((@as(f32, 1.0) - t) * a.z) + (t * b.z),
    };
}
/// Transform a local point to a world position. Rotation in float, translation in double.
pub fn b3TransformWorldPoint(arg_t: b3WorldTransform, arg_p: b3Vec3) callconv(.c) b3Pos {
    var t = arg_t;
    _ = &t;
    var p = arg_p;
    _ = &p;
    var r: b3Vec3 = b3RotateVector(t.q, p);
    _ = &r;
    return b3Pos{
        .x = t.p.x + r.x,
        .y = t.p.y + r.y,
        .z = t.p.z + r.z,
    };
}
/// Transform a world position to a local point. One double subtraction, then float.
pub fn b3InvTransformWorldPoint(arg_t: b3WorldTransform, arg_p: b3Pos) callconv(.c) b3Vec3 {
    var t = arg_t;
    _ = &t;
    var p = arg_p;
    _ = &p;
    var d: b3Vec3 = b3Vec3{
        .x = p.x - t.p.x,
        .y = p.y - t.p.y,
        .z = p.z - t.p.z,
    };
    _ = &d;
    return b3InvRotateVector(t.q, d);
}
/// Relative transform of frame B in frame A. The narrow phase boundary.
pub fn b3InvMulWorldTransforms(arg_A: b3WorldTransform, arg_B: b3WorldTransform) callconv(.c) b3Transform {
    var A = arg_A;
    _ = &A;
    var B = arg_B;
    _ = &B;
    var C: b3Transform = undefined;
    _ = &C;
    C.q = b3InvMulQuat(A.q, B.q);
    var d: b3Vec3 = b3Vec3{
        .x = B.p.x - A.p.x,
        .y = B.p.y - A.p.y,
        .z = B.p.z - A.p.z,
    };
    _ = &d;
    C.p = b3InvRotateVector(A.q, d);
    return C;
}
/// Compose a world transform with a local transform.
pub fn b3MulWorldTransforms(arg_A: b3WorldTransform, arg_B: b3Transform) callconv(.c) b3WorldTransform {
    var A = arg_A;
    _ = &A;
    var B = arg_B;
    _ = &B;
    var C: b3WorldTransform = undefined;
    _ = &C;
    C.q = b3MulQuat(A.q, B.q);
    var r: b3Vec3 = b3RotateVector(A.q, B.p);
    _ = &r;
    C.p = b3Pos{
        .x = A.p.x + r.x,
        .y = A.p.y + r.y,
        .z = A.p.z + r.z,
    };
    return C;
}
/// Shift a world transform into the frame of a base position.
pub fn b3ToRelativeTransform(arg_t: b3WorldTransform, arg_base: b3Pos) callconv(.c) b3Transform {
    var t = arg_t;
    _ = &t;
    var base = arg_base;
    _ = &base;
    var r: b3Transform = undefined;
    _ = &r;
    r.q = t.q;
    r.p = b3Vec3{
        .x = t.p.x - base.x,
        .y = t.p.y - base.y,
        .z = t.p.z - base.z,
    };
    return r;
}
/// Promote a float transform to a world transform. Lossless.
pub fn b3MakeWorldTransform(arg_t: b3Transform) callconv(.c) b3WorldTransform {
    var t = arg_t;
    _ = &t;
    var w: b3WorldTransform = undefined;
    _ = &w;
    w.p = b3ToPos(t.p);
    w.q = t.q;
    return w;
}
/// Translate a local AABB by a world origin, rounding outward so the float box always contains
/// the double box. Far from the origin a plain conversion could clip a shape out of its own box.
/// In float mode the origin is float and the rounding is a no-op.
pub fn b3OffsetAABB(arg_localBox: b3AABB, arg_origin: b3Pos) callconv(.c) b3AABB {
    var localBox = arg_localBox;
    _ = &localBox;
    var origin = arg_origin;
    _ = &origin;
    var out: b3AABB = undefined;
    _ = &out;
    out.lowerBound.x = b3RoundDownFloat(@floatCast(origin.x + localBox.lowerBound.x));
    out.lowerBound.y = b3RoundDownFloat(@floatCast(origin.y + localBox.lowerBound.y));
    out.lowerBound.z = b3RoundDownFloat(@floatCast(origin.z + localBox.lowerBound.z));
    out.upperBound.x = b3RoundUpFloat(@floatCast(origin.x + localBox.upperBound.x));
    out.upperBound.y = b3RoundUpFloat(@floatCast(origin.y + localBox.upperBound.y));
    out.upperBound.z = b3RoundUpFloat(@floatCast(origin.z + localBox.upperBound.z));
    return out;
}
/// Compute the determinant of a 3-by-3 matrix.
pub fn b3Det(arg_m: b3Matrix3) callconv(.c) f32 {
    var m = arg_m;
    _ = &m;
    return b3Dot(m.cx, b3Cross(m.cy, m.cz));
}
/// Multiply a matrix times a column vector.
pub fn b3MulMV(arg_m: b3Matrix3, arg_a: b3Vec3) callconv(.c) b3Vec3 {
    var m = arg_m;
    _ = &m;
    var a = arg_a;
    _ = &a;
    var b: b3Vec3 = b3Vec3{
        .x = ((m.cx.x * a.x) + (m.cy.x * a.y)) + (m.cz.x * a.z),
        .y = ((m.cx.y * a.x) + (m.cy.y * a.y)) + (m.cz.y * a.z),
        .z = ((m.cx.z * a.x) + (m.cy.z * a.y)) + (m.cz.z * a.z),
    };
    _ = &b;
    return b;
}
/// Negate a matrix.
pub fn b3NegateMat3(arg_a: b3Matrix3) callconv(.c) b3Matrix3 {
    var a = arg_a;
    _ = &a;
    return b3Matrix3{
        .cx = b3Vec3{
            .x = -a.cx.x,
            .y = -a.cx.y,
            .z = -a.cx.z,
        },
        .cy = b3Vec3{
            .x = -a.cy.x,
            .y = -a.cy.y,
            .z = -a.cy.z,
        },
        .cz = b3Vec3{
            .x = -a.cz.x,
            .y = -a.cz.y,
            .z = -a.cz.z,
        },
    };
}
/// Matrix addition.
/// @return a + b
pub fn b3AddMM(arg_a: b3Matrix3, arg_b: b3Matrix3) callconv(.c) b3Matrix3 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return b3Matrix3{
        .cx = b3Vec3{
            .x = a.cx.x + b.cx.x,
            .y = a.cx.y + b.cx.y,
            .z = a.cx.z + b.cx.z,
        },
        .cy = b3Vec3{
            .x = a.cy.x + b.cy.x,
            .y = a.cy.y + b.cy.y,
            .z = a.cy.z + b.cy.z,
        },
        .cz = b3Vec3{
            .x = a.cz.x + b.cz.x,
            .y = a.cz.y + b.cz.y,
            .z = a.cz.z + b.cz.z,
        },
    };
}
/// Matrix subtraction.
/// @return a - b
pub fn b3SubMM(arg_a: b3Matrix3, arg_b: b3Matrix3) callconv(.c) b3Matrix3 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    return b3Matrix3{
        .cx = b3Vec3{
            .x = a.cx.x - b.cx.x,
            .y = a.cx.y - b.cx.y,
            .z = a.cx.z - b.cx.z,
        },
        .cy = b3Vec3{
            .x = a.cy.x - b.cy.x,
            .y = a.cy.y - b.cy.y,
            .z = a.cy.z - b.cy.z,
        },
        .cz = b3Vec3{
            .x = a.cz.x - b.cz.x,
            .y = a.cz.y - b.cz.y,
            .z = a.cz.z - b.cz.z,
        },
    };
}
/// Multiply a matrix by a scalar, component-wise.
pub fn b3MulSM(arg_s: f32, arg_a: b3Matrix3) callconv(.c) b3Matrix3 {
    var s = arg_s;
    _ = &s;
    var a = arg_a;
    _ = &a;
    return b3Matrix3{
        .cx = b3Vec3{
            .x = s * a.cx.x,
            .y = s * a.cx.y,
            .z = s * a.cx.z,
        },
        .cy = b3Vec3{
            .x = s * a.cy.x,
            .y = s * a.cy.y,
            .z = s * a.cy.z,
        },
        .cz = b3Vec3{
            .x = s * a.cz.x,
            .y = s * a.cz.y,
            .z = s * a.cz.z,
        },
    };
}
/// Matrix multiplication.
/// @return a * b
pub fn b3MulMM(arg_a: b3Matrix3, arg_b: b3Matrix3) callconv(.c) b3Matrix3 {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var out: b3Matrix3 = undefined;
    _ = &out;
    out.cx = b3MulMV(a, b.cx);
    out.cy = b3MulMV(a, b.cy);
    out.cz = b3MulMV(a, b.cz);
    return out;
}
/// Matrix transpose.
pub fn b3Transpose(arg_m: b3Matrix3) callconv(.c) b3Matrix3 {
    var m = arg_m;
    _ = &m;
    var out: b3Matrix3 = undefined;
    _ = &out;
    out.cx = b3Vec3{
        .x = m.cx.x,
        .y = m.cy.x,
        .z = m.cz.x,
    };
    out.cy = b3Vec3{
        .x = m.cx.y,
        .y = m.cy.y,
        .z = m.cz.y,
    };
    out.cz = b3Vec3{
        .x = m.cx.z,
        .y = m.cy.z,
        .z = m.cz.z,
    };
    return out;
}
/// General matrix inverse.
pub fn b3InvertMatrix(arg_m: b3Matrix3) callconv(.c) b3Matrix3 {
    var m = arg_m;
    _ = &m;
    var det: f32 = b3Det(m);
    _ = &det;
    if (b3AbsFloat(det) > (@as(f32, 1000.0) * __FLT_MIN__)) {
        var invDet: f32 = @as(f32, 1.0) / det;
        _ = &invDet;
        var out: b3Matrix3 = undefined;
        _ = &out;
        out.cx = b3MulSV(invDet, b3Cross(m.cy, m.cz));
        out.cy = b3MulSV(invDet, b3Cross(m.cz, m.cx));
        out.cz = b3MulSV(invDet, b3Cross(m.cx, m.cy));
        return b3Transpose(out);
    }
    return b3Mat3_zero;
}
/// Solve a matrix equation.
/// @return inv(m) * a
pub fn b3Solve3(arg_m: b3Matrix3, arg_a: b3Vec3) callconv(.c) b3Vec3 {
    var m = arg_m;
    _ = &m;
    var a = arg_a;
    _ = &a;
    var det: f32 = b3Det(m);
    _ = &det;
    if (b3AbsFloat(det) > (@as(f32, 1000.0) * __FLT_MIN__)) {
        var invDet: f32 = @as(f32, 1.0) / det;
        _ = &invDet;
        var s: b3Matrix3 = undefined;
        _ = &s;
        s.cx = b3Cross(m.cy, m.cz);
        s.cy = b3Cross(m.cz, m.cx);
        s.cz = b3Cross(m.cx, m.cy);
        var b: b3Vec3 = b3Vec3{
            .x = invDet * b3Dot(s.cx, a),
            .y = invDet * b3Dot(s.cy, a),
            .z = invDet * b3Dot(s.cz, a),
        };
        _ = &b;
        return b;
    }
    return b3Vec3_zero;
}
/// Invert a matrix.
pub fn b3InvertT(arg_m: b3Matrix3) callconv(.c) b3Matrix3 {
    var m = arg_m;
    _ = &m;
    var det: f32 = b3Det(m);
    _ = &det;
    if (b3AbsFloat(det) > (@as(f32, 1000.0) * __FLT_MIN__)) {
        var invDet: f32 = @as(f32, 1.0) / det;
        _ = &invDet;
        var out: b3Matrix3 = undefined;
        _ = &out;
        out.cx = b3MulSV(invDet, b3Cross(m.cy, m.cz));
        out.cy = b3MulSV(invDet, b3Cross(m.cz, m.cx));
        out.cz = b3MulSV(invDet, b3Cross(m.cx, m.cy));
        return out;
    }
    return b3Mat3_zero;
}
/// Get the component-wise absolute value of a matrix.
pub fn b3AbsMatrix3(arg_m: b3Matrix3) callconv(.c) b3Matrix3 {
    var m = arg_m;
    _ = &m;
    var out: b3Matrix3 = undefined;
    _ = &out;
    out.cx = b3Abs(m.cx);
    out.cy = b3Abs(m.cy);
    out.cz = b3Abs(m.cz);
    return out;
}
/// Make a matrix from a quaternion. This is useful if you need to
/// rotate many vectors.
/// The force inline improves the performance of b3ShapeDistance.
pub inline fn b3MakeMatrixFromQuat(arg_q: b3Quat) b3Matrix3 {
    var q = arg_q;
    _ = &q;
    var xx: f32 = q.v.x * q.v.x;
    _ = &xx;
    var yy: f32 = q.v.y * q.v.y;
    _ = &yy;
    var zz: f32 = q.v.z * q.v.z;
    _ = &zz;
    var xy: f32 = q.v.x * q.v.y;
    _ = &xy;
    var xz: f32 = q.v.x * q.v.z;
    _ = &xz;
    var xw: f32 = q.v.x * q.s;
    _ = &xw;
    var yz: f32 = q.v.y * q.v.z;
    _ = &yz;
    var yw: f32 = q.v.y * q.s;
    _ = &yw;
    var zw: f32 = q.v.z * q.s;
    _ = &zw;
    return b3Matrix3{
        .cx = b3Vec3{
            .x = @as(f32, 1.0) - (@as(f32, 2.0) * (yy + zz)),
            .y = @as(f32, 2.0) * (xy + zw),
            .z = @as(f32, 2.0) * (xz - yw),
        },
        .cy = b3Vec3{
            .x = @as(f32, 2.0) * (xy - zw),
            .y = @as(f32, 1.0) - (@as(f32, 2.0) * (xx + zz)),
            .z = @as(f32, 2.0) * (yz + xw),
        },
        .cz = b3Vec3{
            .x = @as(f32, 2.0) * (xz + yw),
            .y = @as(f32, 2.0) * (yz - xw),
            .z = @as(f32, 1.0) - (@as(f32, 2.0) * (xx + yy)),
        },
    };
}
/// Get the inertia tensor of an offset point.
/// https://en.wikipedia.org/wiki/Parallel_axis_theorem
pub extern fn b3Steiner(mass: f32, origin: b3Vec3) b3Matrix3;
/// Get the AABB of a point cloud.
pub fn b3MakeAABB(arg_points: [*c]const b3Vec3, arg_count: c_int, arg_radius: f32) callconv(.c) b3AABB {
    var points = arg_points;
    _ = &points;
    var count = arg_count;
    _ = &count;
    var radius = arg_radius;
    _ = &radius;
    _ = !!(count > @as(c_int, 0)) or ((blk: {
        _ = b3InternalAssert("count > 0", "box3d/include/box3d/math_functions.h", @as(c_int, 955));
        break :blk 0;
    }) != 0);
    var a: b3AABB = b3AABB{
        .lowerBound = points[@as(c_int, 0)],
        .upperBound = points[@as(c_int, 0)],
    };
    _ = &a;
    {
        var i: c_int = 1;
        _ = &i;
        while (i < count) : (i += 1) {
            a.lowerBound = b3Min(a.lowerBound, points[@bitCast(@as(isize, @intCast(i)))]);
            a.upperBound = b3Max(a.upperBound, points[@bitCast(@as(isize, @intCast(i)))]);
        }
    }
    var r: b3Vec3 = b3Vec3{
        .x = radius,
        .y = radius,
        .z = radius,
    };
    _ = &r;
    a.lowerBound = b3Sub(a.lowerBound, r);
    a.upperBound = b3Add(a.upperBound, r);
    return a;
}
/// Does a fully contain b?
pub fn b3AABB_Contains(arg_a: b3AABB, arg_b: b3AABB) callconv(.c) bool {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    if ((a.lowerBound.x > b.lowerBound.x) or (b.upperBound.x > a.upperBound.x)) return @"false" != 0;
    if ((a.lowerBound.y > b.lowerBound.y) or (b.upperBound.y > a.upperBound.y)) return @"false" != 0;
    if ((a.lowerBound.z > b.lowerBound.z) or (b.upperBound.z > a.upperBound.z)) return @"false" != 0;
    return @"true" != 0;
}
/// Get the surface area of an axis-aligned bounding box.
pub fn b3AABB_Area(arg_a: b3AABB) callconv(.c) f32 {
    var a = arg_a;
    _ = &a;
    var delta: b3Vec3 = b3Sub(a.upperBound, a.lowerBound);
    _ = &delta;
    return @as(f32, 2.0) * (((delta.x * delta.y) + (delta.y * delta.z)) + (delta.z * delta.x));
}
/// Get the center of an axis-aligned bounding box.
pub fn b3AABB_Center(arg_a: b3AABB) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    return b3MulSV(0.5, b3Add(a.upperBound, a.lowerBound));
}
/// Get the extents (half-widths) of an axis-aligned bounding box.
pub fn b3AABB_Extents(arg_a: b3AABB) callconv(.c) b3Vec3 {
    var a = arg_a;
    _ = &a;
    return b3MulSV(0.5, b3Sub(a.upperBound, a.lowerBound));
}
/// Get the union of two axis-aligned bounding boxes.
pub fn b3AABB_Union(arg_a: b3AABB, arg_b: b3AABB) callconv(.c) b3AABB {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var out: b3AABB = undefined;
    _ = &out;
    out.lowerBound = b3Min(a.lowerBound, b.lowerBound);
    out.upperBound = b3Max(a.upperBound, b.upperBound);
    return out;
}
/// Add uniform padding to an axis-aligned bounding box.
pub fn b3AABB_Inflate(arg_a: b3AABB, arg_extension: f32) callconv(.c) b3AABB {
    var a = arg_a;
    _ = &a;
    var extension = arg_extension;
    _ = &extension;
    var radius: b3Vec3 = b3Vec3{
        .x = extension,
        .y = extension,
        .z = extension,
    };
    _ = &radius;
    var out: b3AABB = undefined;
    _ = &out;
    out.lowerBound = b3Sub(a.lowerBound, radius);
    out.upperBound = b3Add(a.upperBound, radius);
    return out;
}
/// Do two axis-aligned boxes overlap?
pub fn b3AABB_Overlaps(arg_a: b3AABB, arg_b: b3AABB) callconv(.c) bool {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    if ((a.upperBound.x < b.lowerBound.x) or (a.lowerBound.x > b.upperBound.x)) return @"false" != 0;
    if ((a.upperBound.y < b.lowerBound.y) or (a.lowerBound.y > b.upperBound.y)) return @"false" != 0;
    if ((a.upperBound.z < b.lowerBound.z) or (a.lowerBound.z > b.upperBound.z)) return @"false" != 0;
    return @"true" != 0;
}
/// Transform an axis-aligned bounding box. This can create a larger box
/// than if you recomputed the AABB of the original shape with the transform
/// applied.
pub fn b3AABB_Transform(arg_transform: b3Transform, arg_a: b3AABB) callconv(.c) b3AABB {
    var transform = arg_transform;
    _ = &transform;
    var a = arg_a;
    _ = &a;
    var center: b3Vec3 = b3TransformPoint(transform, b3AABB_Center(a));
    _ = &center;
    var m: b3Matrix3 = b3MakeMatrixFromQuat(transform.q);
    _ = &m;
    var extent: b3Vec3 = b3MulMV(b3AbsMatrix3(m), b3AABB_Extents(a));
    _ = &extent;
    var out: b3AABB = b3AABB{
        .lowerBound = b3Sub(center, extent),
        .upperBound = b3Add(center, extent),
    };
    _ = &out;
    return out;
}
/// Get the closest point on an axis-aligned bounding box.
pub fn b3ClosestPointToAABB(arg_point: b3Vec3, arg_a: b3AABB) callconv(.c) b3Vec3 {
    var point = arg_point;
    _ = &point;
    var a = arg_a;
    _ = &a;
    return b3Clamp(point, a.lowerBound, a.upperBound);
}
pub const struct_b3SegmentDistanceResult = extern struct {
    point1: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    fraction1: f32 = 0,
    point2: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    fraction2: f32 = 0,
};
/// The closest points between to segments or infinite lines.
pub const b3SegmentDistanceResult = struct_b3SegmentDistanceResult;
/// Compute the closest point on the segment a-b to the target q.
pub extern fn b3PointToSegmentDistance(a: b3Vec3, b: b3Vec3, q: b3Vec3) b3Vec3;
/// Compute the closest points on two infinite lines.
pub extern fn b3LineDistance(p1: b3Vec3, d1: b3Vec3, p2: b3Vec3, d2: b3Vec3) b3SegmentDistanceResult;
/// Compute the closest points on two line segments.
pub extern fn b3SegmentDistance(p1: b3Vec3, q1: b3Vec3, p2: b3Vec3, q2: b3Vec3) b3SegmentDistanceResult;
/// Is this a valid number? Not NaN or infinity.
pub extern fn b3IsValidFloat(a: f32) bool;
/// Is this a valid vector? Not NaN or infinity.
pub extern fn b3IsValidVec3(a: b3Vec3) bool;
/// Is this a valid quaternion? Not NaN or infinity. Is normalized.
pub extern fn b3IsValidQuat(q: b3Quat) bool;
/// Is this a valid transform? Not NaN or infinity. Is normalized.
pub extern fn b3IsValidTransform(a: b3Transform) bool;
/// Is this a valid matrix? Not NaN or infinity.
pub extern fn b3IsValidMatrix3(a: b3Matrix3) bool;
/// Is this a valid bounding box? Not Nan or infinity. Upper bound greater than or equal to lower bound.
pub extern fn b3IsValidAABB(a: b3AABB) bool;
/// Is this AABB reasonably close to the origin? See B3_HUGE.
pub extern fn b3IsBoundedAABB(a: b3AABB) bool;
/// Is this AABB valid and reasonable?
pub extern fn b3IsSaneAABB(a: b3AABB) bool;
/// Is this a valid plane? Normal is a unit vector. Not Nan or infinity.
pub extern fn b3IsValidPlane(a: b3Plane) bool;
/// Is this a valid world position? Not NaN or infinity.
pub extern fn b3IsValidPosition(p: b3Pos) bool;
/// Is this a valid world transform? Not NaN or infinity. Rotation is normalized.
pub extern fn b3IsValidWorldTransform(t: b3WorldTransform) bool;
/// Box3D bases all length units on meters, but you may need different units for your game.
/// You can set this value to use different units. This should be done at application startup
/// and only modified once. Default value is 1.
/// @warning This must be modified before any calls to Box3D
pub extern fn b3SetLengthUnitsPerMeter(lengthUnits: f32) void;
/// This is used to fatten AABBs in the dynamic tree. This allows proxies
/// to move by a small amount without triggering a tree adjustment. This is in meters.
/// @warning modifying this can have a significant impact on performance
pub extern fn b3GetLengthUnitsPerMeter() f32;
/// Set the threshold for logging stalls.
pub extern fn b3SetStallThreshold(seconds: f32) void;
/// Get the threshold for logging stalls.
pub extern fn b3GetStallThreshold() f32;
pub const struct_b3WorldId = extern struct {
    index1: u16 = 0,
    generation: u16 = 0,
    /// Store a world id into a uint32_t.
    pub const b3StoreWorldId = __root.b3StoreWorldId;
    /// Destroy a world
    pub const b3DestroyWorld = __root.b3DestroyWorld;
    /// World id validation. Provides validation for up to 64K allocations.
    pub const b3World_IsValid = __root.b3World_IsValid;
    /// Simulate a world for one time step. This performs collision detection, integration, and constraint solution.
    /// @param worldId The world to simulate
    /// @param timeStep The amount of time to simulate, this should be a fixed number. Usually 1/60.
    /// @param subStepCount The number of sub-steps, increasing the sub-step count can increase accuracy. Usually 4.
    pub const b3World_Step = __root.b3World_Step;
    /// Call this to draw shapes and other debug draw data
    pub const b3World_Draw = __root.b3World_Draw;
    /// Get the world's bounds. This is the bounding box that covers the current simulation. May have a small
    /// amount of padding.
    pub const b3World_GetBounds = __root.b3World_GetBounds;
    /// Get the body events for the current time step. The event data is transient. Do not store a reference to this data.
    pub const b3World_GetBodyEvents = __root.b3World_GetBodyEvents;
    /// Get sensor events for the current time step. The event data is transient. Do not store a reference to this data.
    pub const b3World_GetSensorEvents = __root.b3World_GetSensorEvents;
    /// Get contact events for this current time step. The event data is transient. Do not store a reference to this data.
    pub const b3World_GetContactEvents = __root.b3World_GetContactEvents;
    /// Get the joint events for the current time step. The event data is transient. Do not store a reference to this data.
    pub const b3World_GetJointEvents = __root.b3World_GetJointEvents;
    /// Overlap test for all shapes that *potentially* overlap the provided AABB
    pub const b3World_OverlapAABB = __root.b3World_OverlapAABB;
    /// Overlap test for all shapes that overlap the provided shape proxy. The proxy points are relative
    /// to the world origin, which lets the query stay precise far from the world origin.
    pub const b3World_OverlapShape = __root.b3World_OverlapShape;
    /// Cast a ray into the world to collect shapes in the path of the ray.
    /// Your callback function controls whether you get the closest point, any point, or n-points.
    /// @note The callback function may receive shapes in any order
    /// @param worldId The world to cast the ray against
    /// @param origin The start point of the ray
    /// @param translation The translation of the ray from the start point to the end point
    /// @param filter Contains bit flags to filter unwanted shapes from the results
    /// @param fcn A user implemented callback function
    /// @param context A user context that is passed along to the callback function
    /// @return traversal performance counters
    pub const b3World_CastRay = __root.b3World_CastRay;
    /// Cast a ray into the world to collect the closest hit. This is a convenience function. Ignores initial overlap.
    /// This is less general than b3World_CastRay() and does not allow for custom filtering.
    pub const b3World_CastRayClosest = __root.b3World_CastRayClosest;
    /// Cast a shape through the world. Similar to a cast ray except that a shape is cast instead of a point.
    /// The proxy points are relative to the origin and the hit points come back as world positions, so the
    /// cast stays precise far from the world origin.
    /// @see b3World_CastRay
    pub const b3World_CastShape = __root.b3World_CastShape;
    /// Cast a capsule mover through the world. This is a special shape cast that handles sliding along other shapes while reducing
    /// clipping. This is not a good source of information about what the mover is touching. Instead use the planes returned by
    /// b3World_CollideMover.
    /// @param worldId World to cast the mover against
    /// @param origin World position the mover capsule is relative to
    /// @param mover Capsule mover, relative to the origin
    /// @param translation Desired mover translation
    /// @param filter Contains bit flags to filter unwanted shapes from the results
    /// @param fcn Optional callback for custom shape filtering
    /// @param context A user context that is passed along to the callback function
    /// @return the translation fraction
    pub const b3World_CastMover = __root.b3World_CastMover;
    /// Collide a capsule mover with the world, gathering collision planes that can be fed to b3SolvePlanes. Useful for
    /// kinematic character movement. The mover and the returned planes are relative to the origin.
    pub const b3World_CollideMover = __root.b3World_CollideMover;
    /// Enable/disable sleep. If your application does not need sleeping, you can gain some performance
    /// by disabling sleep completely at the world level.
    /// @see b3WorldDef
    pub const b3World_EnableSleeping = __root.b3World_EnableSleeping;
    /// Is body sleeping enabled?
    pub const b3World_IsSleepingEnabled = __root.b3World_IsSleepingEnabled;
    /// Enable/disable continuous collision between dynamic and static bodies. Generally you should keep continuous
    /// collision enabled to prevent fast moving objects from going through static objects. The performance gain from
    /// disabling continuous collision is minor.
    /// @see b3WorldDef
    pub const b3World_EnableContinuous = __root.b3World_EnableContinuous;
    /// Is continuous collision enabled?
    pub const b3World_IsContinuousEnabled = __root.b3World_IsContinuousEnabled;
    /// Adjust the restitution threshold. It is recommended not to make this value very small
    /// because it will prevent bodies from sleeping. Usually in meters per second.
    /// @see b3WorldDef
    pub const b3World_SetRestitutionThreshold = __root.b3World_SetRestitutionThreshold;
    /// Get the restitution speed threshold. Usually in meters per second.
    pub const b3World_GetRestitutionThreshold = __root.b3World_GetRestitutionThreshold;
    /// Adjust the hit event threshold. This controls the collision speed needed to generate a b3ContactHitEvent.
    /// Usually in meters per second.
    /// @see b3WorldDef::hitEventThreshold
    pub const b3World_SetHitEventThreshold = __root.b3World_SetHitEventThreshold;
    /// Get the hit event speed threshold. Usually in meters per second.
    pub const b3World_GetHitEventThreshold = __root.b3World_GetHitEventThreshold;
    /// Register the custom filter callback. This is optional.
    pub const b3World_SetCustomFilterCallback = __root.b3World_SetCustomFilterCallback;
    /// Register the pre-solve callback. This is optional.
    pub const b3World_SetPreSolveCallback = __root.b3World_SetPreSolveCallback;
    /// Set the gravity vector for the entire world. Box3D has no concept of an up direction and this
    /// is left as a decision for the application. Usually in m/s^2.
    /// @see b3WorldDef
    pub const b3World_SetGravity = __root.b3World_SetGravity;
    /// Get the gravity vector
    pub const b3World_GetGravity = __root.b3World_GetGravity;
    /// Apply a radial explosion
    /// @param worldId The world id
    /// @param explosionDef The explosion definition
    pub const b3World_Explode = __root.b3World_Explode;
    /// Adjust contact tuning parameters
    /// @param worldId The world id
    /// @param hertz The contact stiffness (cycles per second)
    /// @param dampingRatio The contact bounciness with 1 being critical damping (non-dimensional)
    /// @param contactSpeed The maximum contact constraint push out speed (meters per second)
    /// @note Advanced feature
    pub const b3World_SetContactTuning = __root.b3World_SetContactTuning;
    /// Set the contact point recycling distance. Setting this to zero disables contact point recycling.
    /// Usually in meters.
    pub const b3World_SetContactRecycleDistance = __root.b3World_SetContactRecycleDistance;
    /// Get the contact point recycling distance. Usually in meters.
    pub const b3World_GetContactRecycleDistance = __root.b3World_GetContactRecycleDistance;
    /// Set the maximum linear speed. Usually in m/s.
    pub const b3World_SetMaximumLinearSpeed = __root.b3World_SetMaximumLinearSpeed;
    /// Get the maximum linear speed. Usually in m/s.
    pub const b3World_GetMaximumLinearSpeed = __root.b3World_GetMaximumLinearSpeed;
    /// Enable/disable constraint warm starting. Advanced feature for testing. Disabling
    /// warm starting greatly reduces stability and provides no performance gain.
    pub const b3World_EnableWarmStarting = __root.b3World_EnableWarmStarting;
    /// Is constraint warm starting enabled?
    pub const b3World_IsWarmStartingEnabled = __root.b3World_IsWarmStartingEnabled;
    /// Get the number of awake bodies
    pub const b3World_GetAwakeBodyCount = __root.b3World_GetAwakeBodyCount;
    /// Get the current world performance profile
    pub const b3World_GetProfile = __root.b3World_GetProfile;
    /// Get world counters and sizes
    pub const b3World_GetCounters = __root.b3World_GetCounters;
    /// Get max capacity. This can be used with b3WorldDef to avoid run-time allocations and copies
    pub const b3World_GetMaxCapacity = __root.b3World_GetMaxCapacity;
    /// Set the user data pointer.
    pub const b3World_SetUserData = __root.b3World_SetUserData;
    /// Get the user data pointer.
    pub const b3World_GetUserData = __root.b3World_GetUserData;
    /// Set the friction callback. Passing NULL resets to default.
    pub const b3World_SetFrictionCallback = __root.b3World_SetFrictionCallback;
    /// Set the restitution callback. Passing NULL resets to default.
    pub const b3World_SetRestitutionCallback = __root.b3World_SetRestitutionCallback;
    /// Set the worker count. Must be in the range [1, B3_MAX_WORKERS]
    pub const b3World_SetWorkerCount = __root.b3World_SetWorkerCount;
    /// Get the worker count.
    pub const b3World_GetWorkerCount = __root.b3World_GetWorkerCount;
    /// Dump memory stats to log.
    pub const b3World_DumpMemoryStats = __root.b3World_DumpMemoryStats;
    /// Dump shape bounds to box3d_bounds.txt
    pub const b3World_DumpShapeBounds = __root.b3World_DumpShapeBounds;
    /// This is for internal testing
    pub const b3World_RebuildStaticTree = __root.b3World_RebuildStaticTree;
    /// This is for internal testing
    pub const b3World_EnableSpeculative = __root.b3World_EnableSpeculative;
    /// Begin recording world mutations into the provided buffer.
    /// The buffer is reset on each call so a single b3Recording can be reused for multiple sessions.
    /// @param worldId the world to record
    /// @param recording the recording handle to write into
    pub const b3World_StartRecording = __root.b3World_StartRecording;
    /// End the current recording session. Writes the trailing geometry registry and
    /// backpatches the header. The buffer remains valid until the recording is destroyed.
    /// @param worldId the world currently being recorded
    pub const b3World_StopRecording = __root.b3World_StopRecording;
    /// Create a rigid body given a definition. No reference to the definition is retained. So you can create the definition
    /// on the stack and pass it as a pointer.
    /// @code{.c}
    /// b3BodyDef bodyDef = b3DefaultBodyDef();
    /// b3BodyId myBodyId = b3CreateBody(myWorldId, &bodyDef);
    /// @endcode
    /// @warning This function is locked during callbacks.
    pub const b3CreateBody = __root.b3CreateBody;
    /// Create a parallel joint
    /// @see b3ParallelJointDef for details
    pub const b3CreateParallelJoint = __root.b3CreateParallelJoint;
    /// Create a distance joint
    /// @see b3DistanceJointDef for details
    pub const b3CreateDistanceJoint = __root.b3CreateDistanceJoint;
    /// Create a motor joint
    /// @see b3MotorJointDef for details
    pub const b3CreateMotorJoint = __root.b3CreateMotorJoint;
    /// Create a filter joint.
    /// @see b3FilterJointDef for details
    pub const b3CreateFilterJoint = __root.b3CreateFilterJoint;
    /// Create a prismatic (slider) joint.
    /// @see b3PrismaticJointDef for details
    pub const b3CreatePrismaticJoint = __root.b3CreatePrismaticJoint;
    /// Create a revolute joint
    /// @see b3RevoluteJointDef for details
    pub const b3CreateRevoluteJoint = __root.b3CreateRevoluteJoint;
    /// Create a spherical joint
    /// @see b3SphericalJointDef for details
    pub const b3CreateSphericalJoint = __root.b3CreateSphericalJoint;
    /// Create a weld joint
    /// @see b3WeldJointDef for details
    pub const b3CreateWeldJoint = __root.b3CreateWeldJoint;
    /// Create a wheel joint.
    /// @see b3WheelJointDef for details.
    pub const b3CreateWheelJoint = __root.b3CreateWheelJoint;
    pub const IsValid = __root.b3World_IsValid;
    pub const Step = __root.b3World_Step;
    pub const Draw = __root.b3World_Draw;
    pub const GetBounds = __root.b3World_GetBounds;
    pub const GetBodyEvents = __root.b3World_GetBodyEvents;
    pub const GetSensorEvents = __root.b3World_GetSensorEvents;
    pub const GetContactEvents = __root.b3World_GetContactEvents;
    pub const GetJointEvents = __root.b3World_GetJointEvents;
    pub const OverlapAABB = __root.b3World_OverlapAABB;
    pub const OverlapShape = __root.b3World_OverlapShape;
    pub const CastRay = __root.b3World_CastRay;
    pub const CastRayClosest = __root.b3World_CastRayClosest;
    pub const CastShape = __root.b3World_CastShape;
    pub const CastMover = __root.b3World_CastMover;
    pub const CollideMover = __root.b3World_CollideMover;
    pub const EnableSleeping = __root.b3World_EnableSleeping;
    pub const IsSleepingEnabled = __root.b3World_IsSleepingEnabled;
    pub const EnableContinuous = __root.b3World_EnableContinuous;
    pub const IsContinuousEnabled = __root.b3World_IsContinuousEnabled;
    pub const SetRestitutionThreshold = __root.b3World_SetRestitutionThreshold;
    pub const GetRestitutionThreshold = __root.b3World_GetRestitutionThreshold;
    pub const SetHitEventThreshold = __root.b3World_SetHitEventThreshold;
    pub const GetHitEventThreshold = __root.b3World_GetHitEventThreshold;
    pub const SetCustomFilterCallback = __root.b3World_SetCustomFilterCallback;
    pub const SetPreSolveCallback = __root.b3World_SetPreSolveCallback;
    pub const SetGravity = __root.b3World_SetGravity;
    pub const GetGravity = __root.b3World_GetGravity;
    pub const Explode = __root.b3World_Explode;
    pub const SetContactTuning = __root.b3World_SetContactTuning;
    pub const SetContactRecycleDistance = __root.b3World_SetContactRecycleDistance;
    pub const GetContactRecycleDistance = __root.b3World_GetContactRecycleDistance;
    pub const SetMaximumLinearSpeed = __root.b3World_SetMaximumLinearSpeed;
    pub const GetMaximumLinearSpeed = __root.b3World_GetMaximumLinearSpeed;
    pub const EnableWarmStarting = __root.b3World_EnableWarmStarting;
    pub const IsWarmStartingEnabled = __root.b3World_IsWarmStartingEnabled;
    pub const GetAwakeBodyCount = __root.b3World_GetAwakeBodyCount;
    pub const GetProfile = __root.b3World_GetProfile;
    pub const GetCounters = __root.b3World_GetCounters;
    pub const GetMaxCapacity = __root.b3World_GetMaxCapacity;
    pub const SetUserData = __root.b3World_SetUserData;
    pub const GetUserData = __root.b3World_GetUserData;
    pub const SetFrictionCallback = __root.b3World_SetFrictionCallback;
    pub const SetRestitutionCallback = __root.b3World_SetRestitutionCallback;
    pub const SetWorkerCount = __root.b3World_SetWorkerCount;
    pub const GetWorkerCount = __root.b3World_GetWorkerCount;
    pub const DumpMemoryStats = __root.b3World_DumpMemoryStats;
    pub const DumpShapeBounds = __root.b3World_DumpShapeBounds;
    pub const RebuildStaticTree = __root.b3World_RebuildStaticTree;
    pub const EnableSpeculative = __root.b3World_EnableSpeculative;
    pub const StartRecording = __root.b3World_StartRecording;
    pub const StopRecording = __root.b3World_StopRecording;
};
/// World id references a world instance. This should be treated as an opaque handle.
pub const b3WorldId = struct_b3WorldId;
pub const struct_b3BodyId = extern struct {
    index1: i32 = 0,
    world0: u16 = 0,
    generation: u16 = 0,
    /// Store a body id into a uint64_t.
    pub const b3StoreBodyId = __root.b3StoreBodyId;
    /// Destroy a rigid body given an id. This destroys all shapes and joints attached to the body.
    /// Do not keep references to the associated shapes and joints.
    pub const b3DestroyBody = __root.b3DestroyBody;
    /// Body identifier validation. A valid body exists in a world and is non-null.
    /// This can be used to detect orphaned ids. Provides validation for up to 64K allocations.
    pub const b3Body_IsValid = __root.b3Body_IsValid;
    /// Get the body type: static, kinematic, or dynamic
    pub const b3Body_GetType = __root.b3Body_GetType;
    /// Change the body type. This is an expensive operation. This automatically updates the mass
    /// properties regardless of the automatic mass setting.
    pub const b3Body_SetType = __root.b3Body_SetType;
    /// Set the body name.
    pub const b3Body_SetName = __root.b3Body_SetName;
    /// Get the body name. Returns an empty string if the name isn't set.
    pub const b3Body_GetName = __root.b3Body_GetName;
    /// Set the user data for a body
    pub const b3Body_SetUserData = __root.b3Body_SetUserData;
    /// Get the user data stored in a body
    pub const b3Body_GetUserData = __root.b3Body_GetUserData;
    /// Get the world position of a body. This is the location of the body origin.
    pub const b3Body_GetPosition = __root.b3Body_GetPosition;
    /// Get the world rotation of a body as a quaternion
    pub const b3Body_GetRotation = __root.b3Body_GetRotation;
    /// Get the world transform of a body.
    pub const b3Body_GetTransform = __root.b3Body_GetTransform;
    /// Set the world transform of a body. This acts as a teleport and is fairly expensive.
    /// @note Generally you should create a body with the intended transform.
    /// @see b3BodyDef::position and b3BodyDef::rotation.
    pub const b3Body_SetTransform = __root.b3Body_SetTransform;
    /// Get a local point on a body given a world point.
    pub const b3Body_GetLocalPoint = __root.b3Body_GetLocalPoint;
    /// Get a world point on a body given a local point.
    pub const b3Body_GetWorldPoint = __root.b3Body_GetWorldPoint;
    /// Get a local vector on a body given a world vector.
    pub const b3Body_GetLocalVector = __root.b3Body_GetLocalVector;
    /// Get a world vector on a body given a local vector.
    pub const b3Body_GetWorldVector = __root.b3Body_GetWorldVector;
    /// Get the linear velocity of a body's center of mass. Usually in meters per second.
    pub const b3Body_GetLinearVelocity = __root.b3Body_GetLinearVelocity;
    /// Get the angular velocity of a body in radians per second.
    pub const b3Body_GetAngularVelocity = __root.b3Body_GetAngularVelocity;
    /// Set the linear velocity of a body at the center of mass. Usually in meters per second.
    pub const b3Body_SetLinearVelocity = __root.b3Body_SetLinearVelocity;
    /// Set the angular velocity of a body in radians per second.
    pub const b3Body_SetAngularVelocity = __root.b3Body_SetAngularVelocity;
    /// Set the velocity to reach the given transform after a given time step.
    /// The result will be close but maybe not exact. This is meant for kinematic bodies.
    /// The target is not applied if the velocity would be below the sleep threshold.
    /// This will optionally wake the body if asleep, but only if the movement is significant.
    pub const b3Body_SetTargetTransform = __root.b3Body_SetTargetTransform;
    /// Get the linear velocity of a local point attached to a body. Usually in meters per second.
    pub const b3Body_GetLocalPointVelocity = __root.b3Body_GetLocalPointVelocity;
    /// Get the linear velocity of a world point attached to a body. Usually in meters per second.
    pub const b3Body_GetWorldPointVelocity = __root.b3Body_GetWorldPointVelocity;
    /// Apply a force at a world point. If the force is not applied at the center of mass,
    /// it will generate a torque and affect the angular velocity. This optionally wakes up the body.
    /// The force is ignored if the body is not awake.
    /// @param bodyId The body id
    /// @param force The world force vector, usually in newtons (N)
    /// @param point The world position of the point of application
    /// @param wake Option to wake up the body
    pub const b3Body_ApplyForce = __root.b3Body_ApplyForce;
    /// Apply a force to the center of mass. This optionally wakes up the body.
    /// The force is ignored if the body is not awake.
    /// @param bodyId The body id
    /// @param force the world force vector, usually in newtons (N).
    /// @param wake also wake up the body
    pub const b3Body_ApplyForceToCenter = __root.b3Body_ApplyForceToCenter;
    /// Apply a torque. This affects the angular velocity without affecting the linear velocity.
    /// This optionally wakes the body. The torque is ignored if the body is not awake.
    /// @param bodyId The body id
    /// @param torque the world torque vector, usually in N*m.
    /// @param wake also wake up the body
    pub const b3Body_ApplyTorque = __root.b3Body_ApplyTorque;
    /// Apply an impulse at a point. This immediately modifies the velocity.
    /// It also modifies the angular velocity if the point of application
    /// is not at the center of mass. This optionally wakes the body.
    /// The impulse is ignored if the body is not awake.
    /// @param bodyId The body id
    /// @param impulse the world impulse vector, usually in N*s or kg*m/s.
    /// @param point the world position of the point of application.
    /// @param wake also wake up the body
    /// @warning This should be used for one-shot impulses. If you need a steady force,
    /// use a force instead, which will work better with the sub-stepping solver.
    pub const b3Body_ApplyLinearImpulse = __root.b3Body_ApplyLinearImpulse;
    /// Apply an impulse to the center of mass. This immediately modifies the velocity.
    /// The impulse is ignored if the body is not awake. This optionally wakes the body.
    /// @param bodyId The body id
    /// @param impulse the world impulse vector, usually in N*s or kg*m/s.
    /// @param wake also wake up the body
    /// @warning This should be used for one-shot impulses. If you need a steady force,
    /// use a force instead, which will work better with the sub-stepping solver.
    pub const b3Body_ApplyLinearImpulseToCenter = __root.b3Body_ApplyLinearImpulseToCenter;
    /// Apply an angular impulse in world space. The impulse is ignored if the body is not awake.
    /// This optionally wakes the body.
    /// @param bodyId The body id
    /// @param impulse the world angular impulse vector, usually in units of kg*m*m/s
    /// @param wake also wake up the body
    /// @warning This should be used for one-shot impulses. If you need a steady torque,
    /// use a torque instead, which will work better with the sub-stepping solver.
    pub const b3Body_ApplyAngularImpulse = __root.b3Body_ApplyAngularImpulse;
    /// Get the mass of the body, usually in kilograms
    pub const b3Body_GetMass = __root.b3Body_GetMass;
    /// Get the rotational inertia of the body in local space, usually in kg*m^2
    pub const b3Body_GetLocalRotationalInertia = __root.b3Body_GetLocalRotationalInertia;
    /// Get the inverse mass of the body, usually in 1/kilograms
    pub const b3Body_GetInverseMass = __root.b3Body_GetInverseMass;
    /// Get the inverse rotational inertia of the body in world space, usually in 1/kg*m^2
    pub const b3Body_GetWorldInverseRotationalInertia = __root.b3Body_GetWorldInverseRotationalInertia;
    /// Get the center of mass position of the body in local space
    pub const b3Body_GetLocalCenter = __root.b3Body_GetLocalCenter;
    /// Get the center of mass position of the body in world space
    pub const b3Body_GetWorldCenter = __root.b3Body_GetWorldCenter;
    /// Override the body's mass properties. Normally this is computed automatically using the
    /// shape geometry and density. This information is lost if a shape is added or removed or if the
    /// body type changes.
    pub const b3Body_SetMassData = __root.b3Body_SetMassData;
    /// Get the mass data for a body
    pub const b3Body_GetMassData = __root.b3Body_GetMassData;
    /// This updates the mass properties to the sum of the mass properties of the shapes.
    /// This normally does not need to be called unless you called SetMassData to override
    /// the mass and you later want to reset the mass.
    /// You may also use this when automatic mass computation has been disabled.
    /// You should call this regardless of body type.
    pub const b3Body_ApplyMassFromShapes = __root.b3Body_ApplyMassFromShapes;
    /// Adjust the linear damping. Normally this is set in b3BodyDef before creation.
    pub const b3Body_SetLinearDamping = __root.b3Body_SetLinearDamping;
    /// Get the current linear damping.
    pub const b3Body_GetLinearDamping = __root.b3Body_GetLinearDamping;
    /// Adjust the angular damping. Normally this is set in b3BodyDef before creation.
    pub const b3Body_SetAngularDamping = __root.b3Body_SetAngularDamping;
    /// Get the current angular damping.
    pub const b3Body_GetAngularDamping = __root.b3Body_GetAngularDamping;
    /// Adjust the gravity scale. Normally this is set in b3BodyDef before creation.
    /// @see b3BodyDef::gravityScale
    pub const b3Body_SetGravityScale = __root.b3Body_SetGravityScale;
    /// Get the current gravity scale
    pub const b3Body_GetGravityScale = __root.b3Body_GetGravityScale;
    /// @return true if this body is awake
    pub const b3Body_IsAwake = __root.b3Body_IsAwake;
    /// Wake a body from sleep. This wakes the entire island the body is touching.
    /// @warning Putting a body to sleep will put the entire island of bodies touching this body to sleep,
    /// which can be expensive and possibly unintuitive.
    pub const b3Body_SetAwake = __root.b3Body_SetAwake;
    /// Enable or disable sleeping for this body. If sleeping is disabled the body will wake.
    pub const b3Body_EnableSleep = __root.b3Body_EnableSleep;
    /// Returns true if sleeping is enabled for this body
    pub const b3Body_IsSleepEnabled = __root.b3Body_IsSleepEnabled;
    /// Set the sleep threshold, usually in meters per second
    pub const b3Body_SetSleepThreshold = __root.b3Body_SetSleepThreshold;
    /// Get the sleep threshold, usually in meters per second.
    pub const b3Body_GetSleepThreshold = __root.b3Body_GetSleepThreshold;
    /// Returns true if this body is enabled
    pub const b3Body_IsEnabled = __root.b3Body_IsEnabled;
    /// Disable a body by removing it completely from the simulation. This is expensive.
    pub const b3Body_Disable = __root.b3Body_Disable;
    /// Enable a body by adding it to the simulation. This is expensive.
    pub const b3Body_Enable = __root.b3Body_Enable;
    /// Set the motion locks on this body.
    pub const b3Body_SetMotionLocks = __root.b3Body_SetMotionLocks;
    /// Get the motion locks for this body.
    pub const b3Body_GetMotionLocks = __root.b3Body_GetMotionLocks;
    /// Set this body to be a bullet. A bullet does continuous collision detection
    /// against dynamic bodies (but not other bullets).
    pub const b3Body_SetBullet = __root.b3Body_SetBullet;
    /// Is this body a bullet?
    pub const b3Body_IsBullet = __root.b3Body_IsBullet;
    /// Allow this body to rotate fast. Useful for axially symmetric bodies, such as vehicle wheels.
    /// Normally rotation speed is clamped to improve CCD. However, this clamping is unnecessary for
    /// bodies that only rotate fast around an axis of symmetry.
    pub const b3Body_AllowFastRotation = __root.b3Body_AllowFastRotation;
    /// Is this body allowed to rotate fast?
    pub const b3Body_IsFastRotationAllowed = __root.b3Body_IsFastRotationAllowed;
    /// Enable or disable contact recycling for this body. Contact recycling is a performance optimization
    /// that reuses contact manifolds when bodies move slightly. Disabling it can avoid ghost collisions
    /// on characters at the cost of higher per-step work. Existing contacts retain their prior setting;
    /// only contacts created after this call see the new value.
    /// @see b3BodyDef::enableContactRecycling
    pub const b3Body_EnableContactRecycling = __root.b3Body_EnableContactRecycling;
    /// Is contact recycling enabled on this body?
    pub const b3Body_IsContactRecyclingEnabled = __root.b3Body_IsContactRecyclingEnabled;
    /// Enable/disable hit events on all shapes
    /// @see b3ShapeDef::enableHitEvents
    pub const b3Body_EnableHitEvents = __root.b3Body_EnableHitEvents;
    /// Get the world that owns this body
    pub const b3Body_GetWorld = __root.b3Body_GetWorld;
    /// Get the number of shapes on this body
    pub const b3Body_GetShapeCount = __root.b3Body_GetShapeCount;
    /// Get the shape ids for all shapes on this body, up to the provided capacity.
    /// @returns the number of shape ids stored in the user array
    pub const b3Body_GetShapes = __root.b3Body_GetShapes;
    /// Get the number of joints on this body
    pub const b3Body_GetJointCount = __root.b3Body_GetJointCount;
    /// Get the joint ids for all joints on this body, up to the provided capacity
    /// @returns the number of joint ids stored in the user array
    pub const b3Body_GetJoints = __root.b3Body_GetJoints;
    /// Get the maximum capacity required for retrieving all the touching contacts on a body
    pub const b3Body_GetContactCapacity = __root.b3Body_GetContactCapacity;
    /// Get the touching contact data for a body
    pub const b3Body_GetContactData = __root.b3Body_GetContactData;
    /// Get the current world AABB that contains all the attached shapes. Note that this may not encompass the body origin.
    /// If there are no shapes attached then the returned AABB is empty and centered on the body origin.
    pub const b3Body_ComputeAABB = __root.b3Body_ComputeAABB;
    /// Get the closest point on a body to a world target.
    pub const b3Body_GetClosestPoint = __root.b3Body_GetClosestPoint;
    /// Cast a ray at a specific body using a specified body transform.
    pub const b3Body_CastRay = __root.b3Body_CastRay;
    /// Cast a shape at a specific body using a specified body transform.
    pub const b3Body_CastShape = __root.b3Body_CastShape;
    /// Overlap a shape with a specific body using a specified body transform.
    pub const b3Body_OverlapShape = __root.b3Body_OverlapShape;
    /// Collide a character mover with a specific body using a specified body transform.
    pub const b3Body_CollideMover = __root.b3Body_CollideMover;
    /// Create a circle shape and attach it to a body. The shape definition and geometry are fully cloned.
    /// Contacts are not created until the next time step.
    /// @return the shape id for accessing the shape
    pub const b3CreateSphereShape = __root.b3CreateSphereShape;
    /// Create a capsule shape and attach it to a body. The shape definition and geometry are fully cloned.
    /// Contacts are not created until the next time step.
    /// @return the shape id for accessing the shape
    pub const b3CreateCapsuleShape = __root.b3CreateCapsuleShape;
    /// Create a convex hull shape and attach it to a body. The shape definition is fully cloned. Contacts are not created
    /// until the next time step.
    /// @return the shape id for accessing the shape
    pub const b3CreateHullShape = __root.b3CreateHullShape;
    /// Create a convex hull shape and attach it to a body. The hull is cloned then transformed with scale applied first.
    /// Use this for non-uniform or mirrored scale or a baked local transform. The baked result is shared through the
    /// world hull database. The shape definition and geometry are fully cloned. Contacts are not created until the next time step.
    /// @return the shape id for accessing the shape
    pub const b3CreateTransformedHullShape = __root.b3CreateTransformedHullShape;
    /// Create a mesh hull shape and attach it to a body. The shape definition is fully cloned but the mesh is not.
    /// Contacts are not created until the next time step.
    /// Mesh collision only creates contacts on static bodies.
    /// @warning this holds reference to the input mesh data which must remain valid for the lifetime of this shape
    /// @return the shape id for accessing the shape
    pub const b3CreateMeshShape = __root.b3CreateMeshShape;
    /// Create a height-field shape and attach it to a body. The shape definition is fully cloned but the height field is not.
    /// Contacts are not created until the next time step.
    /// Height field is only allowed on static bodies.
    /// @warning this holds reference to the input height field which must remain valid for the lifetime of this shape
    /// @return the shape id for accessing the shape
    pub const b3CreateHeightFieldShape = __root.b3CreateHeightFieldShape;
    /// Baked compound shapes are only allowed on static bodies.
    /// Note: runtime compounds are achieved by adding multiple shapes to a body.
    /// Runtime compounds can be dynamic and/or kinematic.
    pub const b3CreateBakedCompoundShape = __root.b3CreateBakedCompoundShape;
    pub const IsValid = __root.b3Body_IsValid;
    pub const GetType = __root.b3Body_GetType;
    pub const SetType = __root.b3Body_SetType;
    pub const SetName = __root.b3Body_SetName;
    pub const GetName = __root.b3Body_GetName;
    pub const SetUserData = __root.b3Body_SetUserData;
    pub const GetUserData = __root.b3Body_GetUserData;
    pub const GetPosition = __root.b3Body_GetPosition;
    pub const GetRotation = __root.b3Body_GetRotation;
    pub const GetTransform = __root.b3Body_GetTransform;
    pub const SetTransform = __root.b3Body_SetTransform;
    pub const GetLocalPoint = __root.b3Body_GetLocalPoint;
    pub const GetWorldPoint = __root.b3Body_GetWorldPoint;
    pub const GetLocalVector = __root.b3Body_GetLocalVector;
    pub const GetWorldVector = __root.b3Body_GetWorldVector;
    pub const GetLinearVelocity = __root.b3Body_GetLinearVelocity;
    pub const GetAngularVelocity = __root.b3Body_GetAngularVelocity;
    pub const SetLinearVelocity = __root.b3Body_SetLinearVelocity;
    pub const SetAngularVelocity = __root.b3Body_SetAngularVelocity;
    pub const SetTargetTransform = __root.b3Body_SetTargetTransform;
    pub const GetLocalPointVelocity = __root.b3Body_GetLocalPointVelocity;
    pub const GetWorldPointVelocity = __root.b3Body_GetWorldPointVelocity;
    pub const ApplyForce = __root.b3Body_ApplyForce;
    pub const ApplyForceToCenter = __root.b3Body_ApplyForceToCenter;
    pub const ApplyTorque = __root.b3Body_ApplyTorque;
    pub const ApplyLinearImpulse = __root.b3Body_ApplyLinearImpulse;
    pub const ApplyLinearImpulseToCenter = __root.b3Body_ApplyLinearImpulseToCenter;
    pub const ApplyAngularImpulse = __root.b3Body_ApplyAngularImpulse;
    pub const GetMass = __root.b3Body_GetMass;
    pub const GetLocalRotationalInertia = __root.b3Body_GetLocalRotationalInertia;
    pub const GetInverseMass = __root.b3Body_GetInverseMass;
    pub const GetWorldInverseRotationalInertia = __root.b3Body_GetWorldInverseRotationalInertia;
    pub const GetLocalCenter = __root.b3Body_GetLocalCenter;
    pub const GetWorldCenter = __root.b3Body_GetWorldCenter;
    pub const SetMassData = __root.b3Body_SetMassData;
    pub const GetMassData = __root.b3Body_GetMassData;
    pub const ApplyMassFromShapes = __root.b3Body_ApplyMassFromShapes;
    pub const SetLinearDamping = __root.b3Body_SetLinearDamping;
    pub const GetLinearDamping = __root.b3Body_GetLinearDamping;
    pub const SetAngularDamping = __root.b3Body_SetAngularDamping;
    pub const GetAngularDamping = __root.b3Body_GetAngularDamping;
    pub const SetGravityScale = __root.b3Body_SetGravityScale;
    pub const GetGravityScale = __root.b3Body_GetGravityScale;
    pub const IsAwake = __root.b3Body_IsAwake;
    pub const SetAwake = __root.b3Body_SetAwake;
    pub const EnableSleep = __root.b3Body_EnableSleep;
    pub const IsSleepEnabled = __root.b3Body_IsSleepEnabled;
    pub const SetSleepThreshold = __root.b3Body_SetSleepThreshold;
    pub const GetSleepThreshold = __root.b3Body_GetSleepThreshold;
    pub const IsEnabled = __root.b3Body_IsEnabled;
    pub const Disable = __root.b3Body_Disable;
    pub const Enable = __root.b3Body_Enable;
    pub const SetMotionLocks = __root.b3Body_SetMotionLocks;
    pub const GetMotionLocks = __root.b3Body_GetMotionLocks;
    pub const SetBullet = __root.b3Body_SetBullet;
    pub const IsBullet = __root.b3Body_IsBullet;
    pub const AllowFastRotation = __root.b3Body_AllowFastRotation;
    pub const IsFastRotationAllowed = __root.b3Body_IsFastRotationAllowed;
    pub const EnableContactRecycling = __root.b3Body_EnableContactRecycling;
    pub const IsContactRecyclingEnabled = __root.b3Body_IsContactRecyclingEnabled;
    pub const EnableHitEvents = __root.b3Body_EnableHitEvents;
    pub const GetWorld = __root.b3Body_GetWorld;
    pub const GetShapeCount = __root.b3Body_GetShapeCount;
    pub const GetShapes = __root.b3Body_GetShapes;
    pub const GetJointCount = __root.b3Body_GetJointCount;
    pub const GetJoints = __root.b3Body_GetJoints;
    pub const GetContactCapacity = __root.b3Body_GetContactCapacity;
    pub const GetContactData = __root.b3Body_GetContactData;
    pub const ComputeAABB = __root.b3Body_ComputeAABB;
    pub const GetClosestPoint = __root.b3Body_GetClosestPoint;
    pub const CastRay = __root.b3Body_CastRay;
    pub const CastShape = __root.b3Body_CastShape;
    pub const OverlapShape = __root.b3Body_OverlapShape;
    pub const CollideMover = __root.b3Body_CollideMover;
};
/// Body id references a body instance. This should be treated as an opaque handle.
pub const b3BodyId = struct_b3BodyId;
pub const struct_b3ShapeId = extern struct {
    index1: i32 = 0,
    world0: u16 = 0,
    generation: u16 = 0,
    /// Store a shape id into a uint64_t.
    pub const b3StoreShapeId = __root.b3StoreShapeId;
    /// Destroy a shape. You may defer the body mass update which can improve performance if several shapes on a
    /// body are destroyed at once.
    /// @see b3Body_ApplyMassFromShapes
    pub const b3DestroyShape = __root.b3DestroyShape;
    /// Shape identifier validation. Provides validation for up to 64K allocations.
    pub const b3Shape_IsValid = __root.b3Shape_IsValid;
    /// Get the type of a shape
    pub const b3Shape_GetType = __root.b3Shape_GetType;
    /// Get the id of the body that a shape is attached to
    pub const b3Shape_GetBody = __root.b3Shape_GetBody;
    /// Get the world that owns this shape
    pub const b3Shape_GetWorld = __root.b3Shape_GetWorld;
    /// Returns true if the shape is a sensor
    pub const b3Shape_IsSensor = __root.b3Shape_IsSensor;
    /// Set the shape name.
    pub const b3Shape_SetName = __root.b3Shape_SetName;
    /// Get the shape name. Returns an empty string if the name isn't set.
    pub const b3Shape_GetName = __root.b3Shape_GetName;
    /// Set the user data for a shape
    pub const b3Shape_SetUserData = __root.b3Shape_SetUserData;
    /// Get the user data for a shape. This is useful when you get a shape id
    /// from an event or query.
    pub const b3Shape_GetUserData = __root.b3Shape_GetUserData;
    /// Set the mass density of a shape, usually in kg/m^3.
    /// This will optionally update the mass properties on the parent body.
    /// @see b3ShapeDef::density, b3Body_ApplyMassFromShapes
    pub const b3Shape_SetDensity = __root.b3Shape_SetDensity;
    /// Get the density of a shape, usually in kg/m^3
    pub const b3Shape_GetDensity = __root.b3Shape_GetDensity;
    /// Set the friction on a shape
    pub const b3Shape_SetFriction = __root.b3Shape_SetFriction;
    /// Get the friction of a shape
    pub const b3Shape_GetFriction = __root.b3Shape_GetFriction;
    /// Set the shape restitution (bounciness)
    pub const b3Shape_SetRestitution = __root.b3Shape_SetRestitution;
    /// Get the shape restitution
    pub const b3Shape_GetRestitution = __root.b3Shape_GetRestitution;
    /// Set the shape base surface material. Does not change per triangle materials.
    pub const b3Shape_SetSurfaceMaterial = __root.b3Shape_SetSurfaceMaterial;
    /// Get the base shape surface material.
    pub const b3Shape_GetSurfaceMaterial = __root.b3Shape_GetSurfaceMaterial;
    /// Get the number of mesh surface materials.
    pub const b3Shape_GetMeshMaterialCount = __root.b3Shape_GetMeshMaterialCount;
    /// Set a surface material for a mesh shape.
    pub const b3Shape_SetMeshMaterial = __root.b3Shape_SetMeshMaterial;
    /// Get a surface material for a mesh shape
    pub const b3Shape_GetMeshSurfaceMaterial = __root.b3Shape_GetMeshSurfaceMaterial;
    /// Get the shape filter
    pub const b3Shape_GetFilter = __root.b3Shape_GetFilter;
    /// Set the current filter. This is almost as expensive as recreating the shape.
    /// @see b3ShapeDef::filter
    /// @param shapeId the shape
    /// @param filter the new filter
    /// @param invokeContacts if true then the shape will have all contacts recomputed the next time step (expensive)
    pub const b3Shape_SetFilter = __root.b3Shape_SetFilter;
    /// Enable sensor events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors.
    /// @see b3ShapeDef::isSensor
    pub const b3Shape_EnableSensorEvents = __root.b3Shape_EnableSensorEvents;
    /// Returns true if sensor events are enabled
    pub const b3Shape_AreSensorEventsEnabled = __root.b3Shape_AreSensorEventsEnabled;
    /// Enable contact events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors.
    /// @see b3ShapeDef::enableContactEvents
    pub const b3Shape_EnableContactEvents = __root.b3Shape_EnableContactEvents;
    /// Returns true if contact events are enabled
    pub const b3Shape_AreContactEventsEnabled = __root.b3Shape_AreContactEventsEnabled;
    /// Enable pre-solve contact events for this shape. Only applies to dynamic bodies. These are expensive
    /// and must be carefully handled due to multithreading. Ignored for sensors.
    /// @see b3PreSolveFcn
    pub const b3Shape_EnablePreSolveEvents = __root.b3Shape_EnablePreSolveEvents;
    /// Returns true if pre-solve events are enabled
    pub const b3Shape_ArePreSolveEventsEnabled = __root.b3Shape_ArePreSolveEventsEnabled;
    /// Enable contact hit events for this shape. Ignored for sensors.
    /// @see b3WorldDef.hitEventThreshold
    pub const b3Shape_EnableHitEvents = __root.b3Shape_EnableHitEvents;
    /// Returns true if hit events are enabled
    pub const b3Shape_AreHitEventsEnabled = __root.b3Shape_AreHitEventsEnabled;
    /// Ray cast a shape directly. The ray runs from origin to origin + translation and the hit point
    /// comes back as a world position, so the cast stays precise far from the world origin.
    pub const b3Shape_RayCast = __root.b3Shape_RayCast;
    /// Get a copy of the shape's sphere. Asserts the type is correct.
    pub const b3Shape_GetSphere = __root.b3Shape_GetSphere;
    /// Get a copy of the shape's capsule. Asserts the type is correct.
    pub const b3Shape_GetCapsule = __root.b3Shape_GetCapsule;
    /// Get the shape's convex hull. Asserts the type is correct.
    pub const b3Shape_GetHull = __root.b3Shape_GetHull;
    /// Get the shape's mesh. Asserts the type is correct.
    pub const b3Shape_GetMesh = __root.b3Shape_GetMesh;
    /// Get the shape's height field. Asserts the type is correct.
    pub const b3Shape_GetHeightField = __root.b3Shape_GetHeightField;
    /// Allows you to change a shape to be a sphere or update the current sphere.
    /// This does not modify the mass properties.
    /// @see b3Body_ApplyMassFromShapes
    pub const b3Shape_SetSphere = __root.b3Shape_SetSphere;
    /// Allows you to change a shape to be a capsule or update the current capsule.
    /// This does not modify the mass properties.
    /// @see b3Body_ApplyMassFromShapes
    pub const b3Shape_SetCapsule = __root.b3Shape_SetCapsule;
    /// Allows you to change a shape to be a hull or update the current hull.
    /// This does not modify the mass properties.
    /// @see b3Body_ApplyMassFromShapes
    pub const b3Shape_SetHull = __root.b3Shape_SetHull;
    /// Allows you to change a shape to be a mesh or update the current mesh.
    /// This does not modify the mass properties.
    /// @see b3Body_ApplyMassFromShapes
    pub const b3Shape_SetMesh = __root.b3Shape_SetMesh;
    /// Get the maximum capacity required for retrieving all the touching contacts on a shape
    pub const b3Shape_GetContactCapacity = __root.b3Shape_GetContactCapacity;
    /// Get the touching contact data for a shape. The provided shapeId will be either shapeIdA or shapeIdB on the contact data.
    /// @note Box3D uses speculative collision so some contact points may be separated.
    /// @returns the number of elements filled in the provided array
    /// @warning do not ignore the return value, it specifies the valid number of elements
    pub const b3Shape_GetContactData = __root.b3Shape_GetContactData;
    /// Get the maximum capacity required for retrieving all the overlapped shapes on a sensor shape.
    /// This returns 0 if the provided shape is not a sensor.
    /// @param shapeId the id of a sensor shape
    /// @returns the required capacity to get all the overlaps in b3Shape_GetSensorOverlaps
    pub const b3Shape_GetSensorCapacity = __root.b3Shape_GetSensorCapacity;
    /// Get the overlap data for a sensor shape.
    /// @param shapeId the id of a sensor shape
    /// @param visitorIds a user allocated array that is filled with the overlapping shapes (visitors)
    /// @param capacity the capacity of overlappedShapes
    /// @returns the number of elements filled in the provided array
    /// @warning do not ignore the return value, it specifies the valid number of elements
    /// @warning overlaps may contain destroyed shapes so use b3Shape_IsValid to confirm each overlap
    pub const b3Shape_GetSensorData = __root.b3Shape_GetSensorData;
    /// Get the current world AABB
    pub const b3Shape_GetAABB = __root.b3Shape_GetAABB;
    /// Compute the mass data for a shape
    pub const b3Shape_ComputeMassData = __root.b3Shape_ComputeMassData;
    /// Get the closest point on a shape to a target point. Target and result are in world space.
    pub const b3Shape_GetClosestPoint = __root.b3Shape_GetClosestPoint;
    /// Apply a wind force to the body for this shape using the density of air. This considers
    /// the projected area of the shape in the wind direction. This also considers
    /// the relative velocity of the shape.
    /// @param shapeId the shape id
    /// @param wind the wind velocity in world space
    /// @param drag the drag coefficient, the force that opposes the relative velocity
    /// @param lift the lift coefficient, the force that is perpendicular to the relative velocity
    /// @param maxSpeed the maximum relative speed. Speed cap is necessary for stability. Typically 10m/s or less.
    /// @param wake should this wake the body
    pub const b3Shape_ApplyWind = __root.b3Shape_ApplyWind;
    pub const IsValid = __root.b3Shape_IsValid;
    pub const GetType = __root.b3Shape_GetType;
    pub const GetBody = __root.b3Shape_GetBody;
    pub const GetWorld = __root.b3Shape_GetWorld;
    pub const IsSensor = __root.b3Shape_IsSensor;
    pub const SetName = __root.b3Shape_SetName;
    pub const GetName = __root.b3Shape_GetName;
    pub const SetUserData = __root.b3Shape_SetUserData;
    pub const GetUserData = __root.b3Shape_GetUserData;
    pub const SetDensity = __root.b3Shape_SetDensity;
    pub const GetDensity = __root.b3Shape_GetDensity;
    pub const SetFriction = __root.b3Shape_SetFriction;
    pub const GetFriction = __root.b3Shape_GetFriction;
    pub const SetRestitution = __root.b3Shape_SetRestitution;
    pub const GetRestitution = __root.b3Shape_GetRestitution;
    pub const SetSurfaceMaterial = __root.b3Shape_SetSurfaceMaterial;
    pub const GetSurfaceMaterial = __root.b3Shape_GetSurfaceMaterial;
    pub const GetMeshMaterialCount = __root.b3Shape_GetMeshMaterialCount;
    pub const SetMeshMaterial = __root.b3Shape_SetMeshMaterial;
    pub const GetMeshSurfaceMaterial = __root.b3Shape_GetMeshSurfaceMaterial;
    pub const GetFilter = __root.b3Shape_GetFilter;
    pub const SetFilter = __root.b3Shape_SetFilter;
    pub const EnableSensorEvents = __root.b3Shape_EnableSensorEvents;
    pub const AreSensorEventsEnabled = __root.b3Shape_AreSensorEventsEnabled;
    pub const EnableContactEvents = __root.b3Shape_EnableContactEvents;
    pub const AreContactEventsEnabled = __root.b3Shape_AreContactEventsEnabled;
    pub const EnablePreSolveEvents = __root.b3Shape_EnablePreSolveEvents;
    pub const ArePreSolveEventsEnabled = __root.b3Shape_ArePreSolveEventsEnabled;
    pub const EnableHitEvents = __root.b3Shape_EnableHitEvents;
    pub const AreHitEventsEnabled = __root.b3Shape_AreHitEventsEnabled;
    pub const RayCast = __root.b3Shape_RayCast;
    pub const GetSphere = __root.b3Shape_GetSphere;
    pub const GetCapsule = __root.b3Shape_GetCapsule;
    pub const GetHull = __root.b3Shape_GetHull;
    pub const GetMesh = __root.b3Shape_GetMesh;
    pub const GetHeightField = __root.b3Shape_GetHeightField;
    pub const SetSphere = __root.b3Shape_SetSphere;
    pub const SetCapsule = __root.b3Shape_SetCapsule;
    pub const SetHull = __root.b3Shape_SetHull;
    pub const SetMesh = __root.b3Shape_SetMesh;
    pub const GetContactCapacity = __root.b3Shape_GetContactCapacity;
    pub const GetContactData = __root.b3Shape_GetContactData;
    pub const GetSensorCapacity = __root.b3Shape_GetSensorCapacity;
    pub const GetSensorData = __root.b3Shape_GetSensorData;
    pub const GetAABB = __root.b3Shape_GetAABB;
    pub const ComputeMassData = __root.b3Shape_ComputeMassData;
    pub const GetClosestPoint = __root.b3Shape_GetClosestPoint;
    pub const ApplyWind = __root.b3Shape_ApplyWind;
};
/// Shape id references a shape instance. This should be treated as an opaque handle.
pub const b3ShapeId = struct_b3ShapeId;
pub const struct_b3JointId = extern struct {
    index1: i32 = 0,
    world0: u16 = 0,
    generation: u16 = 0,
    /// Store a joint id into a uint64_t.
    pub const b3StoreJointId = __root.b3StoreJointId;
    /// Destroy a joint
    pub const b3DestroyJoint = __root.b3DestroyJoint;
    /// Joint identifier validation. Provides validation for up to 64K allocations.
    pub const b3Joint_IsValid = __root.b3Joint_IsValid;
    /// Get the joint type
    pub const b3Joint_GetType = __root.b3Joint_GetType;
    /// Get body A id on a joint
    pub const b3Joint_GetBodyA = __root.b3Joint_GetBodyA;
    /// Get body B id on a joint
    pub const b3Joint_GetBodyB = __root.b3Joint_GetBodyB;
    /// Get the world that owns this joint
    pub const b3Joint_GetWorld = __root.b3Joint_GetWorld;
    /// Set the local frame on bodyA
    pub const b3Joint_SetLocalFrameA = __root.b3Joint_SetLocalFrameA;
    /// Get the local frame on bodyA
    pub const b3Joint_GetLocalFrameA = __root.b3Joint_GetLocalFrameA;
    /// Set the local frame on bodyB
    pub const b3Joint_SetLocalFrameB = __root.b3Joint_SetLocalFrameB;
    /// Get the local frame on bodyB
    pub const b3Joint_GetLocalFrameB = __root.b3Joint_GetLocalFrameB;
    /// Toggle collision between connected bodies
    pub const b3Joint_SetCollideConnected = __root.b3Joint_SetCollideConnected;
    /// Is collision allowed between connected bodies?
    pub const b3Joint_GetCollideConnected = __root.b3Joint_GetCollideConnected;
    /// Set the user data on a joint
    pub const b3Joint_SetUserData = __root.b3Joint_SetUserData;
    /// Get the user data on a joint
    pub const b3Joint_GetUserData = __root.b3Joint_GetUserData;
    /// Wake the bodies connect to this joint
    pub const b3Joint_WakeBodies = __root.b3Joint_WakeBodies;
    /// Get the current constraint force for this joint
    pub const b3Joint_GetConstraintForce = __root.b3Joint_GetConstraintForce;
    /// Get the current constraint torque for this joint
    pub const b3Joint_GetConstraintTorque = __root.b3Joint_GetConstraintTorque;
    /// Get the current linear separation error for this joint. Does not consider admissible movement. Usually in meters.
    pub const b3Joint_GetLinearSeparation = __root.b3Joint_GetLinearSeparation;
    /// Get the current angular separation error for this joint. Does not consider admissible movement. Usually in radians.
    pub const b3Joint_GetAngularSeparation = __root.b3Joint_GetAngularSeparation;
    /// Set the joint constraint tuning. Advanced feature.
    /// @param jointId the joint
    /// @param hertz the stiffness in Hertz (cycles per second)
    /// @param dampingRatio the non-dimensional damping ratio (one for critical damping)
    pub const b3Joint_SetConstraintTuning = __root.b3Joint_SetConstraintTuning;
    /// Get the joint constraint tuning. Advanced feature.
    pub const b3Joint_GetConstraintTuning = __root.b3Joint_GetConstraintTuning;
    /// Set the force threshold for joint events (Newtons)
    pub const b3Joint_SetForceThreshold = __root.b3Joint_SetForceThreshold;
    /// Get the force threshold for joint events (Newtons)
    pub const b3Joint_GetForceThreshold = __root.b3Joint_GetForceThreshold;
    /// Set the torque threshold for joint events (N-m)
    pub const b3Joint_SetTorqueThreshold = __root.b3Joint_SetTorqueThreshold;
    /// Get the torque threshold for joint events (N-m)
    pub const b3Joint_GetTorqueThreshold = __root.b3Joint_GetTorqueThreshold;
    /// Set the spring stiffness in Hertz
    pub const b3ParallelJoint_SetSpringHertz = __root.b3ParallelJoint_SetSpringHertz;
    /// Set the spring damping ratio, non-dimensional
    pub const b3ParallelJoint_SetSpringDampingRatio = __root.b3ParallelJoint_SetSpringDampingRatio;
    /// Get the spring Hertz
    pub const b3ParallelJoint_GetSpringHertz = __root.b3ParallelJoint_GetSpringHertz;
    /// Get the spring damping ratio
    pub const b3ParallelJoint_GetSpringDampingRatio = __root.b3ParallelJoint_GetSpringDampingRatio;
    /// Set the maximum spring torque, usually in newton-meters
    pub const b3ParallelJoint_SetMaxTorque = __root.b3ParallelJoint_SetMaxTorque;
    /// Get the maximum spring torque, usually in newton-meters
    pub const b3ParallelJoint_GetMaxTorque = __root.b3ParallelJoint_GetMaxTorque;
    /// Set the rest length of a distance joint
    /// @param jointId The id for a distance joint
    /// @param length The new distance joint length
    pub const b3DistanceJoint_SetLength = __root.b3DistanceJoint_SetLength;
    /// Get the rest length of a distance joint
    pub const b3DistanceJoint_GetLength = __root.b3DistanceJoint_GetLength;
    /// Enable/disable the distance joint spring. When disabled the distance joint is rigid.
    pub const b3DistanceJoint_EnableSpring = __root.b3DistanceJoint_EnableSpring;
    /// Is the distance joint spring enabled?
    pub const b3DistanceJoint_IsSpringEnabled = __root.b3DistanceJoint_IsSpringEnabled;
    /// Set the force range for the spring.
    pub const b3DistanceJoint_SetSpringForceRange = __root.b3DistanceJoint_SetSpringForceRange;
    /// Get the force range for the spring.
    pub const b3DistanceJoint_GetSpringForceRange = __root.b3DistanceJoint_GetSpringForceRange;
    /// Set the spring stiffness in Hertz
    pub const b3DistanceJoint_SetSpringHertz = __root.b3DistanceJoint_SetSpringHertz;
    /// Set the spring damping ratio, non-dimensional
    pub const b3DistanceJoint_SetSpringDampingRatio = __root.b3DistanceJoint_SetSpringDampingRatio;
    /// Get the spring Hertz
    pub const b3DistanceJoint_GetSpringHertz = __root.b3DistanceJoint_GetSpringHertz;
    /// Get the spring damping ratio
    pub const b3DistanceJoint_GetSpringDampingRatio = __root.b3DistanceJoint_GetSpringDampingRatio;
    /// Enable joint limit. The limit only works if the joint spring is enabled. Otherwise the joint is rigid
    /// and the limit has no effect.
    pub const b3DistanceJoint_EnableLimit = __root.b3DistanceJoint_EnableLimit;
    /// Is the distance joint limit enabled?
    pub const b3DistanceJoint_IsLimitEnabled = __root.b3DistanceJoint_IsLimitEnabled;
    /// Set the minimum and maximum length parameters of a distance joint
    pub const b3DistanceJoint_SetLengthRange = __root.b3DistanceJoint_SetLengthRange;
    /// Get the distance joint minimum length
    pub const b3DistanceJoint_GetMinLength = __root.b3DistanceJoint_GetMinLength;
    /// Get the distance joint maximum length
    pub const b3DistanceJoint_GetMaxLength = __root.b3DistanceJoint_GetMaxLength;
    /// Get the current length of a distance joint
    pub const b3DistanceJoint_GetCurrentLength = __root.b3DistanceJoint_GetCurrentLength;
    /// Enable/disable the distance joint motor
    pub const b3DistanceJoint_EnableMotor = __root.b3DistanceJoint_EnableMotor;
    /// Is the distance joint motor enabled?
    pub const b3DistanceJoint_IsMotorEnabled = __root.b3DistanceJoint_IsMotorEnabled;
    /// Set the distance joint motor speed, usually in meters per second
    pub const b3DistanceJoint_SetMotorSpeed = __root.b3DistanceJoint_SetMotorSpeed;
    /// Get the distance joint motor speed, usually in meters per second
    pub const b3DistanceJoint_GetMotorSpeed = __root.b3DistanceJoint_GetMotorSpeed;
    /// Set the distance joint maximum motor force, usually in newtons
    pub const b3DistanceJoint_SetMaxMotorForce = __root.b3DistanceJoint_SetMaxMotorForce;
    /// Get the distance joint maximum motor force, usually in newtons
    pub const b3DistanceJoint_GetMaxMotorForce = __root.b3DistanceJoint_GetMaxMotorForce;
    /// Get the distance joint current motor force, usually in newtons
    pub const b3DistanceJoint_GetMotorForce = __root.b3DistanceJoint_GetMotorForce;
    /// Set the desired relative linear velocity in meters per second
    pub const b3MotorJoint_SetLinearVelocity = __root.b3MotorJoint_SetLinearVelocity;
    /// Get the desired relative linear velocity in meters per second
    pub const b3MotorJoint_GetLinearVelocity = __root.b3MotorJoint_GetLinearVelocity;
    /// Set the desired relative angular velocity in radians per second
    pub const b3MotorJoint_SetAngularVelocity = __root.b3MotorJoint_SetAngularVelocity;
    /// Get the desired relative angular velocity in radians per second
    pub const b3MotorJoint_GetAngularVelocity = __root.b3MotorJoint_GetAngularVelocity;
    /// Set the motor joint maximum force, usually in newtons
    pub const b3MotorJoint_SetMaxVelocityForce = __root.b3MotorJoint_SetMaxVelocityForce;
    /// Get the motor joint maximum force, usually in newtons
    pub const b3MotorJoint_GetMaxVelocityForce = __root.b3MotorJoint_GetMaxVelocityForce;
    /// Set the motor joint maximum torque, usually in newton-meters
    pub const b3MotorJoint_SetMaxVelocityTorque = __root.b3MotorJoint_SetMaxVelocityTorque;
    /// Get the motor joint maximum torque, usually in newton-meters
    pub const b3MotorJoint_GetMaxVelocityTorque = __root.b3MotorJoint_GetMaxVelocityTorque;
    /// Set the spring linear hertz stiffness
    pub const b3MotorJoint_SetLinearHertz = __root.b3MotorJoint_SetLinearHertz;
    /// Get the spring linear hertz stiffness
    pub const b3MotorJoint_GetLinearHertz = __root.b3MotorJoint_GetLinearHertz;
    /// Set the spring linear damping ratio. Use 1.0 for critical damping.
    pub const b3MotorJoint_SetLinearDampingRatio = __root.b3MotorJoint_SetLinearDampingRatio;
    /// Get the spring linear damping ratio.
    pub const b3MotorJoint_GetLinearDampingRatio = __root.b3MotorJoint_GetLinearDampingRatio;
    /// Set the spring angular hertz stiffness
    pub const b3MotorJoint_SetAngularHertz = __root.b3MotorJoint_SetAngularHertz;
    /// Get the spring angular hertz stiffness
    pub const b3MotorJoint_GetAngularHertz = __root.b3MotorJoint_GetAngularHertz;
    /// Set the spring angular damping ratio. Use 1.0 for critical damping.
    pub const b3MotorJoint_SetAngularDampingRatio = __root.b3MotorJoint_SetAngularDampingRatio;
    /// Get the spring angular damping ratio.
    pub const b3MotorJoint_GetAngularDampingRatio = __root.b3MotorJoint_GetAngularDampingRatio;
    /// Set the maximum spring force in newtons.
    pub const b3MotorJoint_SetMaxSpringForce = __root.b3MotorJoint_SetMaxSpringForce;
    /// Get the maximum spring force in newtons.
    pub const b3MotorJoint_GetMaxSpringForce = __root.b3MotorJoint_GetMaxSpringForce;
    /// Set the maximum spring torque in newtons * meters
    pub const b3MotorJoint_SetMaxSpringTorque = __root.b3MotorJoint_SetMaxSpringTorque;
    /// Get the maximum spring torque in newtons * meters
    pub const b3MotorJoint_GetMaxSpringTorque = __root.b3MotorJoint_GetMaxSpringTorque;
    /// Enable/disable the joint spring.
    pub const b3PrismaticJoint_EnableSpring = __root.b3PrismaticJoint_EnableSpring;
    /// Is the prismatic joint spring enabled or not?
    pub const b3PrismaticJoint_IsSpringEnabled = __root.b3PrismaticJoint_IsSpringEnabled;
    /// Set the prismatic joint stiffness in Hertz.
    /// This should usually be less than a quarter of the simulation rate. For example, if the simulation
    /// runs at 60Hz then the joint stiffness should be 15Hz or less.
    pub const b3PrismaticJoint_SetSpringHertz = __root.b3PrismaticJoint_SetSpringHertz;
    /// Get the prismatic joint stiffness in Hertz
    pub const b3PrismaticJoint_GetSpringHertz = __root.b3PrismaticJoint_GetSpringHertz;
    /// Set the prismatic joint damping ratio (non-dimensional)
    pub const b3PrismaticJoint_SetSpringDampingRatio = __root.b3PrismaticJoint_SetSpringDampingRatio;
    /// Get the prismatic spring damping ratio (non-dimensional)
    pub const b3PrismaticJoint_GetSpringDampingRatio = __root.b3PrismaticJoint_GetSpringDampingRatio;
    /// Set the prismatic joint target translation. Usually in meters.
    pub const b3PrismaticJoint_SetTargetTranslation = __root.b3PrismaticJoint_SetTargetTranslation;
    /// Get the prismatic joint target translation. Usually in meters.
    pub const b3PrismaticJoint_GetTargetTranslation = __root.b3PrismaticJoint_GetTargetTranslation;
    /// Enable/disable a prismatic joint limit
    pub const b3PrismaticJoint_EnableLimit = __root.b3PrismaticJoint_EnableLimit;
    /// Is the prismatic joint limit enabled?
    pub const b3PrismaticJoint_IsLimitEnabled = __root.b3PrismaticJoint_IsLimitEnabled;
    /// Get the prismatic joint lower limit
    pub const b3PrismaticJoint_GetLowerLimit = __root.b3PrismaticJoint_GetLowerLimit;
    /// Get the prismatic joint upper limit
    pub const b3PrismaticJoint_GetUpperLimit = __root.b3PrismaticJoint_GetUpperLimit;
    /// Set the prismatic joint limits
    pub const b3PrismaticJoint_SetLimits = __root.b3PrismaticJoint_SetLimits;
    /// Enable/disable a prismatic joint motor
    pub const b3PrismaticJoint_EnableMotor = __root.b3PrismaticJoint_EnableMotor;
    /// Is the prismatic joint motor enabled?
    pub const b3PrismaticJoint_IsMotorEnabled = __root.b3PrismaticJoint_IsMotorEnabled;
    /// Set the prismatic joint motor speed, usually in meters per second
    pub const b3PrismaticJoint_SetMotorSpeed = __root.b3PrismaticJoint_SetMotorSpeed;
    /// Get the prismatic joint motor speed, usually in meters per second
    pub const b3PrismaticJoint_GetMotorSpeed = __root.b3PrismaticJoint_GetMotorSpeed;
    /// Set the prismatic joint maximum motor force, usually in newtons
    pub const b3PrismaticJoint_SetMaxMotorForce = __root.b3PrismaticJoint_SetMaxMotorForce;
    /// Get the prismatic joint maximum motor force, usually in newtons
    pub const b3PrismaticJoint_GetMaxMotorForce = __root.b3PrismaticJoint_GetMaxMotorForce;
    /// Get the prismatic joint current motor force, usually in newtons
    pub const b3PrismaticJoint_GetMotorForce = __root.b3PrismaticJoint_GetMotorForce;
    /// Get the current joint translation, usually in meters.
    pub const b3PrismaticJoint_GetTranslation = __root.b3PrismaticJoint_GetTranslation;
    /// Get the current joint translation speed, usually in meters per second.
    pub const b3PrismaticJoint_GetSpeed = __root.b3PrismaticJoint_GetSpeed;
    /// Enable/disable the revolute joint spring
    pub const b3RevoluteJoint_EnableSpring = __root.b3RevoluteJoint_EnableSpring;
    /// Is the revolute angular spring enabled?
    pub const b3RevoluteJoint_IsSpringEnabled = __root.b3RevoluteJoint_IsSpringEnabled;
    /// Set the revolute joint spring stiffness in Hertz
    pub const b3RevoluteJoint_SetSpringHertz = __root.b3RevoluteJoint_SetSpringHertz;
    /// Get the revolute joint spring stiffness in Hertz
    pub const b3RevoluteJoint_GetSpringHertz = __root.b3RevoluteJoint_GetSpringHertz;
    /// Set the revolute joint spring damping ratio, non-dimensional
    pub const b3RevoluteJoint_SetSpringDampingRatio = __root.b3RevoluteJoint_SetSpringDampingRatio;
    /// Get the revolute joint spring damping ratio, non-dimensional
    pub const b3RevoluteJoint_GetSpringDampingRatio = __root.b3RevoluteJoint_GetSpringDampingRatio;
    /// Set the revolute joint target angle in radians
    pub const b3RevoluteJoint_SetTargetAngle = __root.b3RevoluteJoint_SetTargetAngle;
    /// Get the revolute joint target angle in radians
    pub const b3RevoluteJoint_GetTargetAngle = __root.b3RevoluteJoint_GetTargetAngle;
    /// Get the revolute joint current angle in radians relative to the reference angle
    /// @see b3RevoluteJointDef::referenceAngle
    pub const b3RevoluteJoint_GetAngle = __root.b3RevoluteJoint_GetAngle;
    /// Enable/disable the revolute joint limit
    pub const b3RevoluteJoint_EnableLimit = __root.b3RevoluteJoint_EnableLimit;
    /// Is the revolute joint limit enabled?
    pub const b3RevoluteJoint_IsLimitEnabled = __root.b3RevoluteJoint_IsLimitEnabled;
    /// Get the revolute joint lower limit in radians
    pub const b3RevoluteJoint_GetLowerLimit = __root.b3RevoluteJoint_GetLowerLimit;
    /// Get the revolute joint upper limit in radians
    pub const b3RevoluteJoint_GetUpperLimit = __root.b3RevoluteJoint_GetUpperLimit;
    /// Set the revolute joint limits in radians
    pub const b3RevoluteJoint_SetLimits = __root.b3RevoluteJoint_SetLimits;
    /// Enable/disable a revolute joint motor
    pub const b3RevoluteJoint_EnableMotor = __root.b3RevoluteJoint_EnableMotor;
    /// Is the revolute joint motor enabled?
    pub const b3RevoluteJoint_IsMotorEnabled = __root.b3RevoluteJoint_IsMotorEnabled;
    /// Set the revolute joint motor speed in radians per second
    pub const b3RevoluteJoint_SetMotorSpeed = __root.b3RevoluteJoint_SetMotorSpeed;
    /// Get the revolute joint motor speed in radians per second
    pub const b3RevoluteJoint_GetMotorSpeed = __root.b3RevoluteJoint_GetMotorSpeed;
    /// Get the revolute joint current motor torque, usually in newton-meters
    pub const b3RevoluteJoint_GetMotorTorque = __root.b3RevoluteJoint_GetMotorTorque;
    /// Set the revolute joint maximum motor torque, usually in newton-meters
    pub const b3RevoluteJoint_SetMaxMotorTorque = __root.b3RevoluteJoint_SetMaxMotorTorque;
    /// Get the revolute joint maximum motor torque, usually in newton-meters
    pub const b3RevoluteJoint_GetMaxMotorTorque = __root.b3RevoluteJoint_GetMaxMotorTorque;
    /// Enable/disable the spherical joint cone limit
    pub const b3SphericalJoint_EnableConeLimit = __root.b3SphericalJoint_EnableConeLimit;
    /// Is the spherical joint cone limit enabled?
    pub const b3SphericalJoint_IsConeLimitEnabled = __root.b3SphericalJoint_IsConeLimitEnabled;
    /// Get the spherical joint cone limit in radians
    pub const b3SphericalJoint_GetConeLimit = __root.b3SphericalJoint_GetConeLimit;
    /// Set the spherical joint limits in radians
    pub const b3SphericalJoint_SetConeLimit = __root.b3SphericalJoint_SetConeLimit;
    /// Get the spherical joint current cone angle in radians.
    pub const b3SphericalJoint_GetConeAngle = __root.b3SphericalJoint_GetConeAngle;
    /// Enable/disable the spherical joint limit
    pub const b3SphericalJoint_EnableTwistLimit = __root.b3SphericalJoint_EnableTwistLimit;
    /// Is the spherical joint limit enabled?
    pub const b3SphericalJoint_IsTwistLimitEnabled = __root.b3SphericalJoint_IsTwistLimitEnabled;
    /// Get the spherical joint lower limit in radians
    pub const b3SphericalJoint_GetLowerTwistLimit = __root.b3SphericalJoint_GetLowerTwistLimit;
    /// Get the spherical joint upper limit in radians
    pub const b3SphericalJoint_GetUpperTwistLimit = __root.b3SphericalJoint_GetUpperTwistLimit;
    /// Set the spherical joint limits in radians
    pub const b3SphericalJoint_SetTwistLimits = __root.b3SphericalJoint_SetTwistLimits;
    /// Get the spherical joint current twist angle in radians.
    pub const b3SphericalJoint_GetTwistAngle = __root.b3SphericalJoint_GetTwistAngle;
    /// Enable/disable the spherical joint spring
    pub const b3SphericalJoint_EnableSpring = __root.b3SphericalJoint_EnableSpring;
    /// Is the spherical angular spring enabled?
    pub const b3SphericalJoint_IsSpringEnabled = __root.b3SphericalJoint_IsSpringEnabled;
    /// Set the spherical joint spring stiffness in Hertz
    pub const b3SphericalJoint_SetSpringHertz = __root.b3SphericalJoint_SetSpringHertz;
    /// Get the spherical joint spring stiffness in Hertz
    pub const b3SphericalJoint_GetSpringHertz = __root.b3SphericalJoint_GetSpringHertz;
    /// Set the spherical joint spring damping ratio, non-dimensional
    pub const b3SphericalJoint_SetSpringDampingRatio = __root.b3SphericalJoint_SetSpringDampingRatio;
    /// Get the spherical joint spring damping ratio, non-dimensional
    pub const b3SphericalJoint_GetSpringDampingRatio = __root.b3SphericalJoint_GetSpringDampingRatio;
    /// Set the spherical joint spring target rotation
    pub const b3SphericalJoint_SetTargetRotation = __root.b3SphericalJoint_SetTargetRotation;
    /// Get the spherical joint spring target rotation
    pub const b3SphericalJoint_GetTargetRotation = __root.b3SphericalJoint_GetTargetRotation;
    /// Enable/disable a spherical joint motor
    pub const b3SphericalJoint_EnableMotor = __root.b3SphericalJoint_EnableMotor;
    /// Is the spherical joint motor enabled?
    pub const b3SphericalJoint_IsMotorEnabled = __root.b3SphericalJoint_IsMotorEnabled;
    /// Set the spherical joint motor velocity in radians per second
    pub const b3SphericalJoint_SetMotorVelocity = __root.b3SphericalJoint_SetMotorVelocity;
    /// Get the spherical joint motor velocity in radians per second
    pub const b3SphericalJoint_GetMotorVelocity = __root.b3SphericalJoint_GetMotorVelocity;
    /// Get the spherical joint current motor torque, usually in newton-meters
    pub const b3SphericalJoint_GetMotorTorque = __root.b3SphericalJoint_GetMotorTorque;
    /// Set the spherical joint maximum motor torque, usually in newton-meters
    pub const b3SphericalJoint_SetMaxMotorTorque = __root.b3SphericalJoint_SetMaxMotorTorque;
    /// Get the spherical joint maximum motor torque, usually in newton-meters
    pub const b3SphericalJoint_GetMaxMotorTorque = __root.b3SphericalJoint_GetMaxMotorTorque;
    /// Set the weld joint linear stiffness in Hertz. 0 is rigid.
    pub const b3WeldJoint_SetLinearHertz = __root.b3WeldJoint_SetLinearHertz;
    /// Get the weld joint linear stiffness in Hertz
    pub const b3WeldJoint_GetLinearHertz = __root.b3WeldJoint_GetLinearHertz;
    /// Set the weld joint linear damping ratio (non-dimensional)
    pub const b3WeldJoint_SetLinearDampingRatio = __root.b3WeldJoint_SetLinearDampingRatio;
    /// Get the weld joint linear damping ratio (non-dimensional)
    pub const b3WeldJoint_GetLinearDampingRatio = __root.b3WeldJoint_GetLinearDampingRatio;
    /// Set the weld joint angular stiffness in Hertz. 0 is rigid.
    pub const b3WeldJoint_SetAngularHertz = __root.b3WeldJoint_SetAngularHertz;
    /// Get the weld joint angular stiffness in Hertz
    pub const b3WeldJoint_GetAngularHertz = __root.b3WeldJoint_GetAngularHertz;
    /// Set weld joint angular damping ratio, non-dimensional
    pub const b3WeldJoint_SetAngularDampingRatio = __root.b3WeldJoint_SetAngularDampingRatio;
    /// Get the weld joint angular damping ratio, non-dimensional
    pub const b3WeldJoint_GetAngularDampingRatio = __root.b3WeldJoint_GetAngularDampingRatio;
    /// Enable/disable the wheel joint spring.
    pub const b3WheelJoint_EnableSuspension = __root.b3WheelJoint_EnableSuspension;
    /// Is the wheel joint spring enabled?
    pub const b3WheelJoint_IsSuspensionEnabled = __root.b3WheelJoint_IsSuspensionEnabled;
    /// Set the wheel joint stiffness in Hertz.
    pub const b3WheelJoint_SetSuspensionHertz = __root.b3WheelJoint_SetSuspensionHertz;
    /// Get the wheel joint stiffness in Hertz.
    pub const b3WheelJoint_GetSuspensionHertz = __root.b3WheelJoint_GetSuspensionHertz;
    /// Set the wheel joint damping ratio, non-dimensional.
    pub const b3WheelJoint_SetSuspensionDampingRatio = __root.b3WheelJoint_SetSuspensionDampingRatio;
    /// Get the wheel joint damping ratio, non-dimensional.
    pub const b3WheelJoint_GetSuspensionDampingRatio = __root.b3WheelJoint_GetSuspensionDampingRatio;
    /// Enable/disable the wheel joint limit.
    pub const b3WheelJoint_EnableSuspensionLimit = __root.b3WheelJoint_EnableSuspensionLimit;
    /// Is the wheel joint limit enabled?
    pub const b3WheelJoint_IsSuspensionLimitEnabled = __root.b3WheelJoint_IsSuspensionLimitEnabled;
    /// Get the wheel joint lower limit.
    pub const b3WheelJoint_GetLowerSuspensionLimit = __root.b3WheelJoint_GetLowerSuspensionLimit;
    /// Get the wheel joint upper limit.
    pub const b3WheelJoint_GetUpperSuspensionLimit = __root.b3WheelJoint_GetUpperSuspensionLimit;
    /// Set the wheel joint limits.
    pub const b3WheelJoint_SetSuspensionLimits = __root.b3WheelJoint_SetSuspensionLimits;
    /// Enable/disable the wheel joint motor.
    pub const b3WheelJoint_EnableSpinMotor = __root.b3WheelJoint_EnableSpinMotor;
    /// Is the wheel joint motor enabled?
    pub const b3WheelJoint_IsSpinMotorEnabled = __root.b3WheelJoint_IsSpinMotorEnabled;
    /// Set the wheel joint motor speed in radians per second.
    pub const b3WheelJoint_SetSpinMotorSpeed = __root.b3WheelJoint_SetSpinMotorSpeed;
    /// Get the wheel joint motor speed in radians per second.
    pub const b3WheelJoint_GetSpinMotorSpeed = __root.b3WheelJoint_GetSpinMotorSpeed;
    /// Set the wheel joint maximum motor torque, usually in newton-meters.
    pub const b3WheelJoint_SetMaxSpinTorque = __root.b3WheelJoint_SetMaxSpinTorque;
    /// Get the wheel joint maximum motor torque, usually in newton-meters.
    pub const b3WheelJoint_GetMaxSpinTorque = __root.b3WheelJoint_GetMaxSpinTorque;
    /// Get the current spin speed in radians per second.
    pub const b3WheelJoint_GetSpinSpeed = __root.b3WheelJoint_GetSpinSpeed;
    /// Get the wheel joint current motor torque, usually in newton-meters.
    pub const b3WheelJoint_GetSpinTorque = __root.b3WheelJoint_GetSpinTorque;
    /// Enable/disable wheel steering. Steering allows the wheel to rotate about the suspension axis.
    pub const b3WheelJoint_EnableSteering = __root.b3WheelJoint_EnableSteering;
    /// Can the wheel steer?
    pub const b3WheelJoint_IsSteeringEnabled = __root.b3WheelJoint_IsSteeringEnabled;
    /// Set the wheel joint steering stiffness in Hertz.
    pub const b3WheelJoint_SetSteeringHertz = __root.b3WheelJoint_SetSteeringHertz;
    /// Get the wheel joint steering stiffness in Hertz.
    pub const b3WheelJoint_GetSteeringHertz = __root.b3WheelJoint_GetSteeringHertz;
    /// Set the wheel joint steering damping ratio, non-dimensional.
    pub const b3WheelJoint_SetSteeringDampingRatio = __root.b3WheelJoint_SetSteeringDampingRatio;
    /// Get the wheel joint steering damping ratio, non-dimensional.
    pub const b3WheelJoint_GetSteeringDampingRatio = __root.b3WheelJoint_GetSteeringDampingRatio;
    /// Set the wheel joint maximum steering torque in N*m.
    pub const b3WheelJoint_SetMaxSteeringTorque = __root.b3WheelJoint_SetMaxSteeringTorque;
    /// Get the wheel joint maximum steering torque in N*m.
    pub const b3WheelJoint_GetMaxSteeringTorque = __root.b3WheelJoint_GetMaxSteeringTorque;
    /// Enable/disable the wheel joint steering limit.
    pub const b3WheelJoint_EnableSteeringLimit = __root.b3WheelJoint_EnableSteeringLimit;
    /// Is the wheel joint steering limit enabled?
    pub const b3WheelJoint_IsSteeringLimitEnabled = __root.b3WheelJoint_IsSteeringLimitEnabled;
    /// Get the wheel joint lower steering limit in radians.
    pub const b3WheelJoint_GetLowerSteeringLimit = __root.b3WheelJoint_GetLowerSteeringLimit;
    /// Get the wheel joint upper steering limit in radians.
    pub const b3WheelJoint_GetUpperSteeringLimit = __root.b3WheelJoint_GetUpperSteeringLimit;
    /// Set the wheel joint steering limits in radians.
    pub const b3WheelJoint_SetSteeringLimits = __root.b3WheelJoint_SetSteeringLimits;
    /// Set the wheel joint target steering angle in radians.
    pub const b3WheelJoint_SetTargetSteeringAngle = __root.b3WheelJoint_SetTargetSteeringAngle;
    /// Get the wheel joint target steering angle in radians.
    pub const b3WheelJoint_GetTargetSteeringAngle = __root.b3WheelJoint_GetTargetSteeringAngle;
    /// Get the current steering angle in radians.
    pub const b3WheelJoint_GetSteeringAngle = __root.b3WheelJoint_GetSteeringAngle;
    /// Get the current steering torque in N*m.
    pub const b3WheelJoint_GetSteeringTorque = __root.b3WheelJoint_GetSteeringTorque;
    pub const IsValid = __root.b3Joint_IsValid;
    pub const GetType = __root.b3Joint_GetType;
    pub const GetBodyA = __root.b3Joint_GetBodyA;
    pub const GetBodyB = __root.b3Joint_GetBodyB;
    pub const GetWorld = __root.b3Joint_GetWorld;
    pub const SetLocalFrameA = __root.b3Joint_SetLocalFrameA;
    pub const GetLocalFrameA = __root.b3Joint_GetLocalFrameA;
    pub const SetLocalFrameB = __root.b3Joint_SetLocalFrameB;
    pub const GetLocalFrameB = __root.b3Joint_GetLocalFrameB;
    pub const SetCollideConnected = __root.b3Joint_SetCollideConnected;
    pub const GetCollideConnected = __root.b3Joint_GetCollideConnected;
    pub const SetUserData = __root.b3Joint_SetUserData;
    pub const GetUserData = __root.b3Joint_GetUserData;
    pub const WakeBodies = __root.b3Joint_WakeBodies;
    pub const GetConstraintForce = __root.b3Joint_GetConstraintForce;
    pub const GetConstraintTorque = __root.b3Joint_GetConstraintTorque;
    pub const GetLinearSeparation = __root.b3Joint_GetLinearSeparation;
    pub const GetAngularSeparation = __root.b3Joint_GetAngularSeparation;
    pub const SetConstraintTuning = __root.b3Joint_SetConstraintTuning;
    pub const GetConstraintTuning = __root.b3Joint_GetConstraintTuning;
    pub const SetForceThreshold = __root.b3Joint_SetForceThreshold;
    pub const GetForceThreshold = __root.b3Joint_GetForceThreshold;
    pub const SetTorqueThreshold = __root.b3Joint_SetTorqueThreshold;
    pub const GetTorqueThreshold = __root.b3Joint_GetTorqueThreshold;
    pub const SetSpringHertz = __root.b3ParallelJoint_SetSpringHertz;
    pub const SetSpringDampingRatio = __root.b3ParallelJoint_SetSpringDampingRatio;
    pub const GetSpringHertz = __root.b3ParallelJoint_GetSpringHertz;
    pub const GetSpringDampingRatio = __root.b3ParallelJoint_GetSpringDampingRatio;
    pub const SetMaxTorque = __root.b3ParallelJoint_SetMaxTorque;
    pub const GetMaxTorque = __root.b3ParallelJoint_GetMaxTorque;
    pub const SetLength = __root.b3DistanceJoint_SetLength;
    pub const GetLength = __root.b3DistanceJoint_GetLength;
    pub const EnableSpring = __root.b3DistanceJoint_EnableSpring;
    pub const IsSpringEnabled = __root.b3DistanceJoint_IsSpringEnabled;
    pub const SetSpringForceRange = __root.b3DistanceJoint_SetSpringForceRange;
    pub const GetSpringForceRange = __root.b3DistanceJoint_GetSpringForceRange;
    pub const EnableLimit = __root.b3DistanceJoint_EnableLimit;
    pub const IsLimitEnabled = __root.b3DistanceJoint_IsLimitEnabled;
    pub const SetLengthRange = __root.b3DistanceJoint_SetLengthRange;
    pub const GetMinLength = __root.b3DistanceJoint_GetMinLength;
    pub const GetMaxLength = __root.b3DistanceJoint_GetMaxLength;
    pub const GetCurrentLength = __root.b3DistanceJoint_GetCurrentLength;
    pub const EnableMotor = __root.b3DistanceJoint_EnableMotor;
    pub const IsMotorEnabled = __root.b3DistanceJoint_IsMotorEnabled;
    pub const SetMotorSpeed = __root.b3DistanceJoint_SetMotorSpeed;
    pub const GetMotorSpeed = __root.b3DistanceJoint_GetMotorSpeed;
    pub const SetMaxMotorForce = __root.b3DistanceJoint_SetMaxMotorForce;
    pub const GetMaxMotorForce = __root.b3DistanceJoint_GetMaxMotorForce;
    pub const GetMotorForce = __root.b3DistanceJoint_GetMotorForce;
    pub const SetLinearVelocity = __root.b3MotorJoint_SetLinearVelocity;
    pub const GetLinearVelocity = __root.b3MotorJoint_GetLinearVelocity;
    pub const SetAngularVelocity = __root.b3MotorJoint_SetAngularVelocity;
    pub const GetAngularVelocity = __root.b3MotorJoint_GetAngularVelocity;
    pub const SetMaxVelocityForce = __root.b3MotorJoint_SetMaxVelocityForce;
    pub const GetMaxVelocityForce = __root.b3MotorJoint_GetMaxVelocityForce;
    pub const SetMaxVelocityTorque = __root.b3MotorJoint_SetMaxVelocityTorque;
    pub const GetMaxVelocityTorque = __root.b3MotorJoint_GetMaxVelocityTorque;
    pub const SetLinearHertz = __root.b3MotorJoint_SetLinearHertz;
    pub const GetLinearHertz = __root.b3MotorJoint_GetLinearHertz;
    pub const SetLinearDampingRatio = __root.b3MotorJoint_SetLinearDampingRatio;
    pub const GetLinearDampingRatio = __root.b3MotorJoint_GetLinearDampingRatio;
    pub const SetAngularHertz = __root.b3MotorJoint_SetAngularHertz;
    pub const GetAngularHertz = __root.b3MotorJoint_GetAngularHertz;
    pub const SetAngularDampingRatio = __root.b3MotorJoint_SetAngularDampingRatio;
    pub const GetAngularDampingRatio = __root.b3MotorJoint_GetAngularDampingRatio;
    pub const SetMaxSpringForce = __root.b3MotorJoint_SetMaxSpringForce;
    pub const GetMaxSpringForce = __root.b3MotorJoint_GetMaxSpringForce;
    pub const SetMaxSpringTorque = __root.b3MotorJoint_SetMaxSpringTorque;
    pub const GetMaxSpringTorque = __root.b3MotorJoint_GetMaxSpringTorque;
    pub const SetTargetTranslation = __root.b3PrismaticJoint_SetTargetTranslation;
    pub const GetTargetTranslation = __root.b3PrismaticJoint_GetTargetTranslation;
    pub const GetLowerLimit = __root.b3PrismaticJoint_GetLowerLimit;
    pub const GetUpperLimit = __root.b3PrismaticJoint_GetUpperLimit;
    pub const SetLimits = __root.b3PrismaticJoint_SetLimits;
    pub const GetTranslation = __root.b3PrismaticJoint_GetTranslation;
    pub const GetSpeed = __root.b3PrismaticJoint_GetSpeed;
    pub const SetTargetAngle = __root.b3RevoluteJoint_SetTargetAngle;
    pub const GetTargetAngle = __root.b3RevoluteJoint_GetTargetAngle;
    pub const GetAngle = __root.b3RevoluteJoint_GetAngle;
    pub const GetMotorTorque = __root.b3RevoluteJoint_GetMotorTorque;
    pub const SetMaxMotorTorque = __root.b3RevoluteJoint_SetMaxMotorTorque;
    pub const GetMaxMotorTorque = __root.b3RevoluteJoint_GetMaxMotorTorque;
    pub const EnableConeLimit = __root.b3SphericalJoint_EnableConeLimit;
    pub const IsConeLimitEnabled = __root.b3SphericalJoint_IsConeLimitEnabled;
    pub const GetConeLimit = __root.b3SphericalJoint_GetConeLimit;
    pub const SetConeLimit = __root.b3SphericalJoint_SetConeLimit;
    pub const GetConeAngle = __root.b3SphericalJoint_GetConeAngle;
    pub const EnableTwistLimit = __root.b3SphericalJoint_EnableTwistLimit;
    pub const IsTwistLimitEnabled = __root.b3SphericalJoint_IsTwistLimitEnabled;
    pub const GetLowerTwistLimit = __root.b3SphericalJoint_GetLowerTwistLimit;
    pub const GetUpperTwistLimit = __root.b3SphericalJoint_GetUpperTwistLimit;
    pub const SetTwistLimits = __root.b3SphericalJoint_SetTwistLimits;
    pub const GetTwistAngle = __root.b3SphericalJoint_GetTwistAngle;
    pub const SetTargetRotation = __root.b3SphericalJoint_SetTargetRotation;
    pub const GetTargetRotation = __root.b3SphericalJoint_GetTargetRotation;
    pub const SetMotorVelocity = __root.b3SphericalJoint_SetMotorVelocity;
    pub const GetMotorVelocity = __root.b3SphericalJoint_GetMotorVelocity;
    pub const EnableSuspension = __root.b3WheelJoint_EnableSuspension;
    pub const IsSuspensionEnabled = __root.b3WheelJoint_IsSuspensionEnabled;
    pub const SetSuspensionHertz = __root.b3WheelJoint_SetSuspensionHertz;
    pub const GetSuspensionHertz = __root.b3WheelJoint_GetSuspensionHertz;
    pub const SetSuspensionDampingRatio = __root.b3WheelJoint_SetSuspensionDampingRatio;
    pub const GetSuspensionDampingRatio = __root.b3WheelJoint_GetSuspensionDampingRatio;
    pub const EnableSuspensionLimit = __root.b3WheelJoint_EnableSuspensionLimit;
    pub const IsSuspensionLimitEnabled = __root.b3WheelJoint_IsSuspensionLimitEnabled;
    pub const GetLowerSuspensionLimit = __root.b3WheelJoint_GetLowerSuspensionLimit;
    pub const GetUpperSuspensionLimit = __root.b3WheelJoint_GetUpperSuspensionLimit;
    pub const SetSuspensionLimits = __root.b3WheelJoint_SetSuspensionLimits;
    pub const EnableSpinMotor = __root.b3WheelJoint_EnableSpinMotor;
    pub const IsSpinMotorEnabled = __root.b3WheelJoint_IsSpinMotorEnabled;
    pub const SetSpinMotorSpeed = __root.b3WheelJoint_SetSpinMotorSpeed;
    pub const GetSpinMotorSpeed = __root.b3WheelJoint_GetSpinMotorSpeed;
    pub const SetMaxSpinTorque = __root.b3WheelJoint_SetMaxSpinTorque;
    pub const GetMaxSpinTorque = __root.b3WheelJoint_GetMaxSpinTorque;
    pub const GetSpinSpeed = __root.b3WheelJoint_GetSpinSpeed;
    pub const GetSpinTorque = __root.b3WheelJoint_GetSpinTorque;
    pub const EnableSteering = __root.b3WheelJoint_EnableSteering;
    pub const IsSteeringEnabled = __root.b3WheelJoint_IsSteeringEnabled;
    pub const SetSteeringHertz = __root.b3WheelJoint_SetSteeringHertz;
    pub const GetSteeringHertz = __root.b3WheelJoint_GetSteeringHertz;
    pub const SetSteeringDampingRatio = __root.b3WheelJoint_SetSteeringDampingRatio;
    pub const GetSteeringDampingRatio = __root.b3WheelJoint_GetSteeringDampingRatio;
    pub const SetMaxSteeringTorque = __root.b3WheelJoint_SetMaxSteeringTorque;
    pub const GetMaxSteeringTorque = __root.b3WheelJoint_GetMaxSteeringTorque;
    pub const EnableSteeringLimit = __root.b3WheelJoint_EnableSteeringLimit;
    pub const IsSteeringLimitEnabled = __root.b3WheelJoint_IsSteeringLimitEnabled;
    pub const GetLowerSteeringLimit = __root.b3WheelJoint_GetLowerSteeringLimit;
    pub const GetUpperSteeringLimit = __root.b3WheelJoint_GetUpperSteeringLimit;
    pub const SetSteeringLimits = __root.b3WheelJoint_SetSteeringLimits;
    pub const SetTargetSteeringAngle = __root.b3WheelJoint_SetTargetSteeringAngle;
    pub const GetTargetSteeringAngle = __root.b3WheelJoint_GetTargetSteeringAngle;
    pub const GetSteeringAngle = __root.b3WheelJoint_GetSteeringAngle;
    pub const GetSteeringTorque = __root.b3WheelJoint_GetSteeringTorque;
};
/// Joint id references a joint instance. This should be treated as an opaque handle.
pub const b3JointId = struct_b3JointId;
pub const struct_b3ContactId = extern struct {
    index1: i32 = 0,
    world0: u16 = 0,
    padding: i16 = 0,
    generation: u32 = 0,
    /// Store a contact id into three uint32 values
    pub const b3StoreContactId = __root.b3StoreContactId;
    /// Contact identifier validation. Provides validation for up to 2^32 allocations.
    pub const b3Contact_IsValid = __root.b3Contact_IsValid;
    /// Get the manifolds for a contact. The manifold may have no points if the contact is not touching.
    pub const b3Contact_GetData = __root.b3Contact_GetData;
    pub const IsValid = __root.b3Contact_IsValid;
    pub const GetData = __root.b3Contact_GetData;
};
/// Contact id references a contact instance. This should be treated as an opaque handle.
pub const b3ContactId = struct_b3ContactId;
pub const b3_nullWorldId: b3WorldId = b3WorldId{
    .index1 = 0,
    .generation = 0,
};
pub const b3_nullBodyId: b3BodyId = b3BodyId{
    .index1 = 0,
    .world0 = 0,
    .generation = 0,
};
pub const b3_nullShapeId: b3ShapeId = b3ShapeId{
    .index1 = 0,
    .world0 = 0,
    .generation = 0,
};
pub const b3_nullJointId: b3JointId = b3JointId{
    .index1 = 0,
    .world0 = 0,
    .generation = 0,
};
pub const b3_nullContactId: b3ContactId = b3ContactId{
    .index1 = 0,
    .world0 = 0,
    .padding = 0,
    .generation = 0,
};
/// Store a world id into a uint32_t.
pub fn b3StoreWorldId(arg_id: b3WorldId) callconv(.c) u32 {
    var id = arg_id;
    _ = &id;
    return (@as(u32, id.index1) << @intCast(@as(u32, 16))) | @as(u32, id.generation);
}
/// Load a uint32_t into a world id.
pub fn b3LoadWorldId(arg_x: u32) callconv(.c) b3WorldId {
    var x = arg_x;
    _ = &x;
    var id: b3WorldId = b3WorldId{
        .index1 = @truncate(x >> @intCast(@as(u32, 16))),
        .generation = @truncate(x),
    };
    _ = &id;
    return id;
}
/// Store a body id into a uint64_t.
pub fn b3StoreBodyId(arg_id: b3BodyId) callconv(.c) u64 {
    var id = arg_id;
    _ = &id;
    return ((@as(u64, @bitCast(@as(c_long, id.index1))) << @intCast(@as(u64, 32))) | (@as(u64, id.world0) << @intCast(@as(u64, 16)))) | @as(u64, id.generation);
}
/// Load a uint64_t into a body id.
pub fn b3LoadBodyId(arg_x: u64) callconv(.c) b3BodyId {
    var x = arg_x;
    _ = &x;
    var id: b3BodyId = b3BodyId{
        .index1 = @bitCast(@as(c_uint, @truncate(x >> @intCast(@as(u64, 32))))),
        .world0 = @truncate(x >> @intCast(@as(u64, 16))),
        .generation = @truncate(x),
    };
    _ = &id;
    return id;
}
/// Store a shape id into a uint64_t.
pub fn b3StoreShapeId(arg_id: b3ShapeId) callconv(.c) u64 {
    var id = arg_id;
    _ = &id;
    return ((@as(u64, @bitCast(@as(c_long, id.index1))) << @intCast(@as(u64, 32))) | (@as(u64, id.world0) << @intCast(@as(u64, 16)))) | @as(u64, id.generation);
}
/// Load a uint64_t into a shape id.
pub fn b3LoadShapeId(arg_x: u64) callconv(.c) b3ShapeId {
    var x = arg_x;
    _ = &x;
    var id: b3ShapeId = b3ShapeId{
        .index1 = @bitCast(@as(c_uint, @truncate(x >> @intCast(@as(u64, 32))))),
        .world0 = @truncate(x >> @intCast(@as(u64, 16))),
        .generation = @truncate(x),
    };
    _ = &id;
    return id;
}
/// Store a joint id into a uint64_t.
pub fn b3StoreJointId(arg_id: b3JointId) callconv(.c) u64 {
    var id = arg_id;
    _ = &id;
    return ((@as(u64, @bitCast(@as(c_long, id.index1))) << @intCast(@as(u64, 32))) | (@as(u64, id.world0) << @intCast(@as(u64, 16)))) | @as(u64, id.generation);
}
/// Load a uint64_t into a joint id.
pub fn b3LoadJointId(arg_x: u64) callconv(.c) b3JointId {
    var x = arg_x;
    _ = &x;
    var id: b3JointId = b3JointId{
        .index1 = @bitCast(@as(c_uint, @truncate(x >> @intCast(@as(u64, 32))))),
        .world0 = @truncate(x >> @intCast(@as(u64, 16))),
        .generation = @truncate(x),
    };
    _ = &id;
    return id;
}
/// Store a contact id into three uint32 values
pub fn b3StoreContactId(arg_id: b3ContactId, arg_values: [*c]u32) callconv(.c) void {
    var id = arg_id;
    _ = &id;
    var values = arg_values;
    _ = &values;
    values[@as(c_int, 0)] = @bitCast(@as(c_int, id.index1));
    values[@as(c_int, 1)] = id.world0;
    values[@as(c_int, 2)] = id.generation;
}
/// Load a contact id from three uint32 values.
pub fn b3LoadContactId(arg_values: [*c]u32) callconv(.c) b3ContactId {
    var values = arg_values;
    _ = &values;
    var id: b3ContactId = undefined;
    _ = &id;
    id.index1 = @bitCast(@as(c_uint, @truncate(values[@as(c_int, 0)])));
    id.world0 = @truncate(values[@as(c_int, 1)]);
    id.padding = 0;
    id.generation = values[@as(c_int, 2)];
    return id;
}
/// Task interface
/// This is the prototype for a Box3D task. Your task system is expected to run this callback on a worker thread,
/// exactly once per enqueue, passing back the same taskContext pointer supplied to b3EnqueueTaskCallback.
/// @ingroup world
pub const b3TaskCallback = fn (taskContext: ?*anyopaque) callconv(.c) void;
/// These functions can be provided to Box3D to invoke a task system.
/// Returns a pointer to the user's task object. May be nullptr. A nullptr indicates to Box3D that the work was executed
/// serially within the callback and there is no need to call b3FinishTaskCallback. Otherwise the returned
/// value must be non-null will be passed to b3FinishTaskCallback as the userTask.
/// @param task the Box3D task to be called by the scheduler
/// @param taskContext the Box3D context object that the scheduler must pass to the task
/// @param userContext the scheduler context object that is opaque to Box3D
/// @param taskName the Box3D task name that the scheduler can use for diagnostics
/// @ingroup world
pub const b3EnqueueTaskCallback = fn (task: ?*const b3TaskCallback, taskContext: ?*anyopaque, userContext: ?*anyopaque, taskName: [*c]const u8) callconv(.c) ?*anyopaque;
/// Finishes a user task object that wraps a Box3D task. This must block until the task has completed.
/// The step blocks here on the tasks it spawned, so b3World_Step holds its stack across every
/// fork/join. Drive it from a thread you can dedicate to the step, or from a fiber this callback can
/// park to free the underlying thread. In a job system that cannot park a job's stack, do not call
/// b3World_Step from inside a job: a job that blocks on its own sub-jobs without yielding its thread
/// can deadlock. The in-tree scheduler instead runs other pending tasks on the waiting thread.
/// @ingroup world
pub const b3FinishTaskCallback = fn (userTask: ?*anyopaque, userContext: ?*anyopaque) callconv(.c) void;
/// A capsule is an extruded sphere
pub const b3_capsuleShape: c_int = 0;
/// A baked compound shape composed of spheres, capsules, hulls, and meshes
pub const b3_compoundShape: c_int = 1;
/// A height field useful for terrain
pub const b3_heightShape: c_int = 2;
/// A convex hull
pub const b3_hullShape: c_int = 3;
/// A triangle soup
pub const b3_meshShape: c_int = 4;
/// A sphere with an offset
pub const b3_sphereShape: c_int = 5;
pub const b3_shapeTypeCount: c_int = 6;
pub const enum_b3ShapeType = c_uint;
/// The number of shape types
pub const b3ShapeType = enum_b3ShapeType;
pub const struct_b3Capsule = extern struct {
    /// Local center of the first hemisphere
    center1: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Local center of the second hemisphere
    center2: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The radius of the hemispheres
    radius: f32 = 0,
    /// Compute mass properties of a capsule
    pub const b3ComputeCapsuleMass = __root.b3ComputeCapsuleMass;
    /// Compute the bounding box of a transformed capsule
    pub const b3ComputeCapsuleAABB = __root.b3ComputeCapsuleAABB;
    /// Overlap shape versus capsule
    pub const b3OverlapCapsule = __root.b3OverlapCapsule;
    /// Ray cast versus capsule in local space. A zero length ray is a point query. Initial overlap
    /// reports a hit at the ray origin with zero fraction and zero normal.
    pub const b3RayCastCapsule = __root.b3RayCastCapsule;
    /// Shape cast versus a capsule. Initial overlap is treated as a miss.
    pub const b3ShapeCastCapsule = __root.b3ShapeCastCapsule;
};
/// A solid capsule can be viewed as two hemispheres connected
/// by a rectangle.
pub const b3Capsule = struct_b3Capsule;
pub const struct_b3TreeNodeChildren = extern struct {
    /// child node index 1
    child1: c_int = 0,
    /// child node index 2
    child2: c_int = 0,
};
/// Tree node child indices. For internal usage.
pub const b3TreeNodeChildren = struct_b3TreeNodeChildren;
const union_unnamed_3 = extern union {
    children: b3TreeNodeChildren,
    userData: u64,
};
const union_unnamed_4 = extern union {
    parent: c_int,
    next: c_int,
};
pub const struct_b3TreeNode = extern struct {
    aabb: b3AABB = @import("std").mem.zeroes(b3AABB),
    categoryBits: u64 = 0,
    unnamed_0: union_unnamed_3 = @import("std").mem.zeroes(union_unnamed_3),
    unnamed_1: union_unnamed_4 = @import("std").mem.zeroes(union_unnamed_4),
    height: u16 = 0,
    flags: u16 = 0,
};
/// A node in the dynamic tree. This is private data placed here for performance reasons.
/// todo test padding to 64 bytes to avoid straddling cache lines
pub const b3TreeNode = struct_b3TreeNode;
pub const struct_b3DynamicTree = extern struct {
    /// The dynamic tree version. Always the first field. Useful
    /// if the tree is serialized.
    version: u64 = 0,
    /// The tree nodes
    nodes: [*c]b3TreeNode = null,
    /// The root index
    root: c_int = 0,
    /// The number of nodes
    nodeCount: c_int = 0,
    /// The allocated node space
    nodeCapacity: c_int = 0,
    /// Number of proxies created
    proxyCount: c_int = 0,
    /// Node free list
    freeList: c_int = 0,
    /// Leaf indices for rebuild
    leafIndices: [*c]c_int = null,
    /// Leaf bounding boxes for rebuild
    leafBoxes: [*c]b3AABB = null,
    /// Leaf bounding box centers for rebuild
    leafCenters: [*c]b3Vec3 = null,
    /// Bins for sorting during rebuild
    binIndices: [*c]c_int = null,
    /// Allocated space for rebuilding
    rebuildCapacity: c_int = 0,
    /// Destroy the tree, freeing the node pool.
    pub const b3DynamicTree_Destroy = __root.b3DynamicTree_Destroy;
    /// Create a proxy. Provide an AABB and a userData value.
    pub const b3DynamicTree_CreateProxy = __root.b3DynamicTree_CreateProxy;
    /// Destroy a proxy. This asserts if the id is invalid.
    pub const b3DynamicTree_DestroyProxy = __root.b3DynamicTree_DestroyProxy;
    /// Move a proxy to a new AABB by removing and reinserting into the tree.
    pub const b3DynamicTree_MoveProxy = __root.b3DynamicTree_MoveProxy;
    /// Enlarge a proxy and enlarge ancestors as necessary.
    pub const b3DynamicTree_EnlargeProxy = __root.b3DynamicTree_EnlargeProxy;
    /// Modify the category bits on a proxy. This is an expensive operation.
    pub const b3DynamicTree_SetCategoryBits = __root.b3DynamicTree_SetCategoryBits;
    /// Get the category bits on a proxy.
    pub const b3DynamicTree_GetCategoryBits = __root.b3DynamicTree_GetCategoryBits;
    /// Query an AABB for overlapping proxies. The callback function is called for each proxy that overlaps the supplied AABB.
    /// @return performance data
    pub const b3DynamicTree_Query = __root.b3DynamicTree_Query;
    /// Query an AABB for the closest object. The callback function is called for each proxy that might be closest to the supplied
    /// point.
    /// @param tree the dynamic tree to query
    /// @param point the query point
    /// @param maskBits nodes are skipped if the bit-wise AND with the node category bits is zero
    /// @param requireAllBits nodes are skipped if the bit-wise AND with the node category bits does not equal the maskBits
    /// @param callback a user provided instance of b3TreeQueryClosestCallbackFcn
    /// @param context a user context object that is provided to the callback
    /// @param minDistanceSqr the initial and final minimum squared distance. Provide a small initial to restrict the search and
    /// improve performance. If the value is large this query has performance that scales linearly with the number of proxies and
    /// would be slower than a brute force search.
    /// @return performance data
    pub const b3DynamicTree_QueryClosest = __root.b3DynamicTree_QueryClosest;
    /// Ray cast against the proxies in the tree. This relies on the callback
    /// to perform an exact ray cast in the case where the proxy contains a shape.
    /// The callback also performs any collision filtering. This has performance
    /// roughly equal to k * log(n), where k is the number of collisions and n is the
    /// number of proxies in the tree.
    /// Bit-wise filtering using mask bits can greatly improve performance in some scenarios.
    /// However, this filtering may be approximate, so the user should still apply filtering to results.
    /// @param tree the dynamic tree to ray cast
    /// @param input the ray cast input data. The ray extends from p1 to p1 + maxFraction * (p2 - p1)
    /// @param maskBits bit mask test: `bool accept = (maskBits & node->categoryBits) != 0;`
    /// @param requireAllBits modifies bit mask test: `bool accept = (maskBits & node->categoryBits) == maskBits;`
    /// @param callback a callback function that is called for each proxy that is hit by the ray
    /// @param context user context that is passed to the callback
    /// @return performance data
    pub const b3DynamicTree_RayCast = __root.b3DynamicTree_RayCast;
    /// Sweep an AABB through the tree. The box is in the tree's world float frame and the callback
    /// re-differences each shape at full precision against the query origin. Used by the large world
    /// spatial queries so the tree traversal stays float while the narrow phase stays precise.
    pub const b3DynamicTree_BoxCast = __root.b3DynamicTree_BoxCast;
    /// Get the height of the binary tree.
    pub const b3DynamicTree_GetHeight = __root.b3DynamicTree_GetHeight;
    /// Get the ratio of the sum of the node areas to the root area.
    pub const b3DynamicTree_GetAreaRatio = __root.b3DynamicTree_GetAreaRatio;
    /// Get the bounding box that contains the entire tree
    pub const b3DynamicTree_GetRootBounds = __root.b3DynamicTree_GetRootBounds;
    /// Get the number of proxies created
    pub const b3DynamicTree_GetProxyCount = __root.b3DynamicTree_GetProxyCount;
    /// Rebuild the tree while retaining subtrees that haven't changed. Returns the number of boxes sorted.
    pub const b3DynamicTree_Rebuild = __root.b3DynamicTree_Rebuild;
    /// Get the number of bytes used by this tree
    pub const b3DynamicTree_GetByteCount = __root.b3DynamicTree_GetByteCount;
    /// Validate this tree. For testing.
    pub const b3DynamicTree_Validate = __root.b3DynamicTree_Validate;
    /// Validate this tree has no enlarged AABBs. For testing.
    pub const b3DynamicTree_ValidateNoEnlarged = __root.b3DynamicTree_ValidateNoEnlarged;
    /// Save this tree to a file for debugging
    pub const b3DynamicTree_Save = __root.b3DynamicTree_Save;
    /// Get proxy user data
    pub const b3DynamicTree_GetUserData = __root.b3DynamicTree_GetUserData;
    /// Get the AABB of a proxy
    pub const b3DynamicTree_GetAABB = __root.b3DynamicTree_GetAABB;
    pub const Destroy = __root.b3DynamicTree_Destroy;
    pub const CreateProxy = __root.b3DynamicTree_CreateProxy;
    pub const DestroyProxy = __root.b3DynamicTree_DestroyProxy;
    pub const MoveProxy = __root.b3DynamicTree_MoveProxy;
    pub const EnlargeProxy = __root.b3DynamicTree_EnlargeProxy;
    pub const SetCategoryBits = __root.b3DynamicTree_SetCategoryBits;
    pub const GetCategoryBits = __root.b3DynamicTree_GetCategoryBits;
    pub const Query = __root.b3DynamicTree_Query;
    pub const QueryClosest = __root.b3DynamicTree_QueryClosest;
    pub const RayCast = __root.b3DynamicTree_RayCast;
    pub const BoxCast = __root.b3DynamicTree_BoxCast;
    pub const GetHeight = __root.b3DynamicTree_GetHeight;
    pub const GetAreaRatio = __root.b3DynamicTree_GetAreaRatio;
    pub const GetRootBounds = __root.b3DynamicTree_GetRootBounds;
    pub const GetProxyCount = __root.b3DynamicTree_GetProxyCount;
    pub const Rebuild = __root.b3DynamicTree_Rebuild;
    pub const GetByteCount = __root.b3DynamicTree_GetByteCount;
    pub const Validate = __root.b3DynamicTree_Validate;
    pub const ValidateNoEnlarged = __root.b3DynamicTree_ValidateNoEnlarged;
    pub const Save = __root.b3DynamicTree_Save;
    pub const GetUserData = __root.b3DynamicTree_GetUserData;
    pub const GetAABB = __root.b3DynamicTree_GetAABB;
};
/// The dynamic tree structure. This should be considered private data.
/// It is placed here for performance reasons.
pub const b3DynamicTree = struct_b3DynamicTree;
pub const struct_b3CompoundData = extern struct {
    /// The compound version is always first.
    version: u64 = 0,
    /// The total number of bytes for this compound.
    byteCount: c_int = 0,
    /// Offset of the tree node array in bytes from the struct address.
    nodeOffset: c_int = 0,
    /// Immutable dynamic tree. The tree node pointer must be fixed up using the node offset
    tree: b3DynamicTree = @import("std").mem.zeroes(b3DynamicTree),
    /// Offset of the material array in bytes from the struct address.
    materialOffset: c_int = 0,
    /// The number of materials.
    materialCount: c_int = 0,
    /// Offset of the capsule array in bytes from the struct address.
    capsuleOffset: c_int = 0,
    /// The number of capsules.
    capsuleCount: c_int = 0,
    /// Offset of the hull instance array in bytes from the struct address.
    hullOffset: c_int = 0,
    /// The number of hull instances.
    hullCount: c_int = 0,
    /// The number of unique hulls. Diagnostic.
    sharedHullCount: c_int = 0,
    /// Offset of the mesh instance array in bytes from the struct address.
    meshOffset: c_int = 0,
    /// The number of mesh instances.
    meshCount: c_int = 0,
    /// The number of unique meshes. Diagnostic.
    sharedMeshCount: c_int = 0,
    /// Offset of the sphere array in bytes from the struct address.
    sphereOffset: c_int = 0,
    /// The number of spheres.
    sphereCount: c_int = 0,
    /// Get a child shape of a compound.
    pub const b3GetCompoundChild = __root.b3GetCompoundChild;
    /// Query a compound shape for children that overlap an AABB.
    pub const b3QueryCompound = __root.b3QueryCompound;
    /// Access a child capsule by index.
    pub const b3GetCompoundCapsule = __root.b3GetCompoundCapsule;
    /// Access a child hull by index.
    pub const b3GetCompoundHull = __root.b3GetCompoundHull;
    /// Access a child mesh by index.
    pub const b3GetCompoundMesh = __root.b3GetCompoundMesh;
    /// Access a child sphere by index.
    pub const b3GetCompoundSphere = __root.b3GetCompoundSphere;
    /// Access the compound material array.
    pub const b3GetCompoundMaterials = __root.b3GetCompoundMaterials;
    /// Destroy a compound shape.
    pub const b3DestroyCompound = __root.b3DestroyCompound;
    /// Cast the provided compound data to bytes, setting the internal pointers to null.
    /// Use this before serializing the compound bytes.
    pub const b3ConvertCompoundToBytes = __root.b3ConvertCompoundToBytes;
    /// Compute the bounding box of a compound
    pub const b3ComputeCompoundAABB = __root.b3ComputeCompoundAABB;
    /// Overlap shape versus compound
    pub const b3OverlapCompound = __root.b3OverlapCompound;
    /// Ray cast versus compound in local space. A zero length ray is a point query. Initial overlap
    /// with a child reports a hit at the ray origin with zero fraction and zero normal.
    pub const b3RayCastCompound = __root.b3RayCastCompound;
    /// Shape cast versus compound. Initial overlap is treated as a miss.
    pub const b3ShapeCastCompound = __root.b3ShapeCastCompound;
};
/// The data for a baked compound shape. This is a potentially large yet highly optimized
/// data structure. It can contain thousands of child shapes, yet at runtime it populates
/// into the world as a single shape in the runtime broad-phase.
/// This data structure has data living off the end and must be accessed using offsets.
/// Accessors are provided for user relevant data.
/// Note: you don't need to use this to create runtime compounds. For runtime compounds you can
/// add multiple shapes to a body using the regular shape creation functions.
pub const b3CompoundData = struct_b3CompoundData;
pub const struct_b3HeightFieldData = extern struct {
    /// Version must be first and match B3_HEIGHT_FIELD_VERSION
    version: u64 = 0,
    /// The total number of bytes for this height field.
    byteCount: c_int = 0,
    /// Hash of this height field (this field is zero when the hash is computed).
    hash: u32 = 0,
    /// The local axis-aligned bounding box.
    aabb: b3AABB = @import("std").mem.zeroes(b3AABB),
    /// The minimum y value.
    minHeight: f32 = 0,
    /// The maximum y value
    maxHeight: f32 = 0,
    /// The quantization scale.
    heightScale: f32 = 0,
    /// The overall scale.
    scale: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The number of grid columns along the local x-axis.
    columnCount: c_int = 0,
    /// The number of grid rows along the local z-axis.
    rowCount: c_int = 0,
    /// Offset of the compressed height array in bytes from the struct address.
    /// uint16_t, one per grid point.
    heightsOffset: c_int = 0,
    /// Offset of the material index array in bytes from the struct address.
    /// uint8_t, one per cell.
    materialOffset: c_int = 0,
    /// Offset of the flag array in bytes from the struct address.
    /// uint8_t, one per triangle.
    flagsOffset: c_int = 0,
    /// Triangle winding.
    clockwise: bool = false,
    /// Explicit padding. Identity is a content hash over raw bytes, so there must
    /// be no unnamed padding for struct copies to scramble.
    padding: [3]u8 = @import("std").mem.zeroes([3]u8),
    /// Get read only compressed heights. One uint16_t per grid point.
    pub const b3GetHeightFieldCompressedHeights = __root.b3GetHeightFieldCompressedHeights;
    /// Get read only material indices. One uint8_t per cell.
    pub const b3GetHeightFieldMaterialIndices = __root.b3GetHeightFieldMaterialIndices;
    /// Get read only triangle flags. One uint8_t per triangle.
    pub const b3GetHeightFieldFlags = __root.b3GetHeightFieldFlags;
    /// Destroy a height field.
    pub const b3DestroyHeightField = __root.b3DestroyHeightField;
    /// Compute the bounding box of a transformed height-field
    pub const b3ComputeHeightFieldAABB = __root.b3ComputeHeightFieldAABB;
    /// Overlap shape versus height field
    pub const b3OverlapHeightField = __root.b3OverlapHeightField;
    /// Ray cast versus height field in local space. A thin surface with no interior, so there is no overlap case.
    pub const b3RayCastHeightField = __root.b3RayCastHeightField;
    /// Shape cast versus a height field. Initial overlap is treated as a miss.
    pub const b3ShapeCastHeightField = __root.b3ShapeCastHeightField;
    /// Query a height field for triangles overlapping a bounding box in local space. May have false positives. Useful for debug draw.
    /// @param heightField the height field to query
    /// @param bounds the bounding box in local space
    /// @param fcn a user function to collect triangles
    /// @param context the context sent to the user function.
    pub const b3QueryHeightField = __root.b3QueryHeightField;
};
/// A height field with compressed storage.
/// @note This data structure has data hanging off the end and cannot be directly copied.
pub const b3HeightFieldData = struct_b3HeightFieldData;
pub const struct_b3HullData = extern struct {
    /// Version must be first and match B3_HULL_VERSION
    version: u64 = 0,
    /// The total number of bytes for this hull.
    byteCount: c_int = 0,
    /// Hash of this hull (this field is zero when the hash is computed).
    hash: u32 = 0,
    /// Axis-aligned box in local space.
    aabb: b3AABB = @import("std").mem.zeroes(b3AABB),
    /// Surface area, typically in squared meters.
    surfaceArea: f32 = 0,
    /// Volume, typically in m^3.
    volume: f32 = 0,
    /// The radius of the largest sphere at the center.
    innerRadius: f32 = 0,
    /// The local centroid
    center: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The inertia tensor about the centroid.
    centralInertia: b3Matrix3 = @import("std").mem.zeroes(b3Matrix3),
    /// The vertex count.
    vertexCount: c_int = 0,
    /// Offset of the vertex array in bytes from the struct address.
    vertexOffset: c_int = 0,
    /// Offset of the point array in bytes from the struct address.
    pointOffset: c_int = 0,
    /// This is the half-edge count (double the edge count)
    edgeCount: c_int = 0,
    /// Offset of the edge array in bytes from the struct address.
    edgeOffset: c_int = 0,
    /// The face count. Hulls faces are convex polygons.
    faceCount: c_int = 0,
    /// Offset of the face plane array in bytes from the struct address.
    planeOffset: c_int = 0,
    /// Offset of the face array in bytes from the struct address.
    faceOffset: c_int = 0,
    /// Offset of structure of array (SOA) vertices
    soaVertexOffset: c_int = 0,
    /// Offset of structure of array (SOA) unit normal vectors
    soaNormalOffset: c_int = 0,
    /// Explicit padding. Hull identity is a content hash and memcmp over raw bytes,
    /// so there must be no unnamed padding for struct copies to scramble.
    padding: c_int = 0,
    /// Get read only hull vertices.
    pub const b3GetHullVertices = __root.b3GetHullVertices;
    /// Get read only hull points.
    pub const b3GetHullPoints = __root.b3GetHullPoints;
    /// Get read only hull half edges.
    pub const b3GetHullEdges = __root.b3GetHullEdges;
    /// Get read only hull planes.
    pub const b3GetHullPlanes = __root.b3GetHullPlanes;
    /// Get read only hull faces.
    pub const b3GetHullFaces = __root.b3GetHullFaces;
    /// Get read only SOA vertices. This is an array of vertices with all x values,
    /// y values, and z values as separate arrays. The array lengths are padded to
    /// a multiple of 4. The padded values are repeats of the first value.
    pub const b3GetHullSoaVertices = __root.b3GetHullSoaVertices;
    /// Get read only SOA unit normal vectors. This is an array of normals with all x values,
    /// y values, and z values as separate arrays. The array lengths are padded to
    /// a multiple of 4. The padded values are repeats of the first value.
    pub const b3GetHullSoaNormals = __root.b3GetHullSoaNormals;
    /// Deep clone a hull.
    pub const b3CloneHull = __root.b3CloneHull;
    /// Clone and transform a hull. Supports non-uniform and mirroring scale.
    pub const b3CloneAndTransformHull = __root.b3CloneAndTransformHull;
    /// Destroy a hull.
    pub const b3DestroyHull = __root.b3DestroyHull;
    /// Compute mass properties of a hull
    pub const b3ComputeHullMass = __root.b3ComputeHullMass;
    /// Compute the bounding box of a transformed hull
    pub const b3ComputeHullAABB = __root.b3ComputeHullAABB;
    /// Overlap shape versus hull
    pub const b3OverlapHull = __root.b3OverlapHull;
    /// Ray cast versus hull shape in local space. A zero length ray is a point query. Initial overlap
    /// reports a hit at the ray origin with zero fraction and zero normal.
    pub const b3RayCastHull = __root.b3RayCastHull;
    /// Shape cast versus a hull. Initial overlap is treated as a miss.
    pub const b3ShapeCastHull = __root.b3ShapeCastHull;
};
/// A convex hull.
/// @note This data structure has data hanging off the end and cannot be directly copied.
pub const b3HullData = struct_b3HullData;
pub const struct_b3MeshData = extern struct {
    /// Version must be first.
    version: u64 = 0,
    /// The total number of bytes for this mesh.
    byteCount: c_int = 0,
    /// Hash of this mesh (this field is zero when the hash is computed)
    hash: u32 = 0,
    /// Local axis-aligned box.
    bounds: b3AABB = @import("std").mem.zeroes(b3AABB),
    /// Combined surface area of all triangles. Single-sided.
    surfaceArea: f32 = 0,
    /// The height of the bounding volume hierarchy.
    treeHeight: c_int = 0,
    /// The number of degenerate triangles. Diagnostic.
    degenerateCount: c_int = 0,
    /// Offset of the node array in bytes from the struct address.
    nodeOffset: c_int = 0,
    /// The number of BVH nodes.
    nodeCount: c_int = 0,
    /// Offset of the vertex array in bytes from the struct address.
    vertexOffset: c_int = 0,
    /// The number of vertices.
    vertexCount: c_int = 0,
    /// Offset of the triangle array in bytes from the struct address.
    triangleOffset: c_int = 0,
    /// The number of triangles.
    triangleCount: c_int = 0,
    /// Offset of the material array in bytes from the struct address.
    materialOffset: c_int = 0,
    /// The number of materials.
    materialCount: c_int = 0,
    /// Offset of the triangle flag array in bytes from the struct address.
    flagsOffset: c_int = 0,
    /// Get read only mesh BVH nodes.
    pub const b3GetMeshNodes = __root.b3GetMeshNodes;
    /// Get read only mesh vertices.
    pub const b3GetMeshVertices = __root.b3GetMeshVertices;
    /// Get read only mesh triangles.
    pub const b3GetMeshTriangles = __root.b3GetMeshTriangles;
    /// Get read only mesh materials. The count is equal to the triangle count.
    pub const b3GetMeshMaterialIndices = __root.b3GetMeshMaterialIndices;
    /// Get read only mesh flags. The count is equal to the triangle count.
    pub const b3GetMeshFlags = __root.b3GetMeshFlags;
    /// Destroy a mesh.
    pub const b3DestroyMesh = __root.b3DestroyMesh;
    /// Get the height of the mesh BVH.
    pub const b3GetHeight = __root.b3GetHeight;
    /// Compute the bounding box of a transformed mesh. Scale may be non-uniform and have negative components.
    pub const b3ComputeMeshAABB = __root.b3ComputeMeshAABB;
};
/// This is a sorted triangle collision bounding volume hierarchy.
/// @note This struct has data hanging off the end and cannot be directly copied.
pub const b3MeshData = struct_b3MeshData;
pub const struct_b3Mesh = extern struct {
    /// Immutable pointer to the mesh data.
    data: [*c]const b3MeshData = null,
    /// This scale may be non-uniform and have negative components. However,
    /// no component may be very small in magnitude.
    scale: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Overlap shape versus mesh
    pub const b3OverlapMesh = __root.b3OverlapMesh;
    /// Ray cast versus mesh in local space. A thin surface with no interior, so there is no overlap case.
    pub const b3RayCastMesh = __root.b3RayCastMesh;
    /// Shape cast versus a mesh. Initial overlap is treated as a miss.
    pub const b3ShapeCastMesh = __root.b3ShapeCastMesh;
    /// Query a mesh for triangles overlapping a bounding box in local space. May have false positives. Useful for debug draw.
    /// @param mesh the mesh to query, includes scale
    /// @param bounds the bounding box in local space
    /// @param fcn a user function to collect triangles
    /// @param context the context sent to the user function.
    pub const b3QueryMesh = __root.b3QueryMesh;
};
/// This allows mesh data to be re-used with different scales.
pub const b3Mesh = struct_b3Mesh;
pub const struct_b3Sphere = extern struct {
    /// The local center
    center: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The radius
    radius: f32 = 0,
    /// Compute mass properties of a sphere
    pub const b3ComputeSphereMass = __root.b3ComputeSphereMass;
    /// Compute the bounding box of a transformed sphere
    pub const b3ComputeSphereAABB = __root.b3ComputeSphereAABB;
    /// Overlap shape versus sphere
    pub const b3OverlapSphere = __root.b3OverlapSphere;
    /// Ray cast versus sphere in local space. A zero length ray is a point query. Initial overlap
    /// reports a hit at the ray origin with zero fraction and zero normal.
    pub const b3RayCastSphere = __root.b3RayCastSphere;
    /// Ray cast versus a hollow sphere shell in local space. Unlike the solid sphere a ray starting
    /// inside is not an overlap: it passes through and hits the far wall.
    pub const b3RayCastHollowSphere = __root.b3RayCastHollowSphere;
    /// Shape cast versus a sphere. Initial overlap is treated as a miss.
    pub const b3ShapeCastSphere = __root.b3ShapeCastSphere;
};
/// A solid sphere
pub const b3Sphere = struct_b3Sphere;
const union_unnamed_2 = extern union {
    capsule: [*c]const b3Capsule,
    compound: [*c]const b3CompoundData,
    heightField: [*c]const b3HeightFieldData,
    hull: [*c]const b3HullData,
    mesh: [*c]const b3Mesh,
    sphere: [*c]const b3Sphere,
};
pub const struct_b3DebugShape = extern struct {
    /// Shape id.
    shapeId: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// Shape type.
    type: b3ShapeType = @import("std").mem.zeroes(b3ShapeType),
    unnamed_0: union_unnamed_2 = @import("std").mem.zeroes(union_unnamed_2),
};
/// This is sent to the user for debug shape creation. The user should know the type in case they have
/// custom sphere or capsule rendering.
pub const b3DebugShape = struct_b3DebugShape;
/// The user needs to be able to create debug draw shapes for multi-pass rendering to work efficiently.
/// These user shapes are created and destroyed via callback so they can be bound to shape lifetime and scaling updates.
/// @ingroup debug_draw
pub const b3CreateDebugShapeCallback = fn (debugShape: [*c]const b3DebugShape, userContext: ?*anyopaque) callconv(.c) ?*anyopaque;
pub const b3DestroyDebugShapeCallback = fn (userShape: ?*anyopaque, userContext: ?*anyopaque) callconv(.c) void;
/// Optional friction mixing callback. This intentionally provides no context objects because this is called
/// from a worker thread.
/// @warning This function should not attempt to modify Box3D state or user application state.
/// @ingroup world
pub const b3FrictionCallback = fn (frictionA: f32, userMaterialIdA: u64, frictionB: f32, userMaterialIdB: u64) callconv(.c) f32;
/// Optional restitution mixing callback. This intentionally provides no context objects because this is called
/// from a worker thread.
/// @warning This function should not attempt to modify Box3D state or user application state.
/// @ingroup world
pub const b3RestitutionCallback = fn (restitutionA: f32, userMaterialIdA: u64, restitutionB: f32, userMaterialIdB: u64) callconv(.c) f32;
/// Prototype for a contact filter callback.
/// This is called when a contact pair is considered for collision. This allows you to
/// perform custom logic to prevent collision between shapes. This is only called if
/// one of the two shapes has custom filtering enabled. @see b3ShapeDef.
/// Notes:
/// - this function must be thread-safe
/// - this is only called if one of the two shapes has enabled custom filtering
/// - this is called only for awake dynamic bodies
/// Return false if you want to disable the collision
/// @warning Do not attempt to modify the world inside this callback
/// @ingroup world
pub const b3CustomFilterFcn = fn (shapeIdA: b3ShapeId, shapeIdB: b3ShapeId, context: ?*anyopaque) callconv(.c) bool;
/// Prototype for a pre-solve callback.
/// This is called after a contact is updated. This allows you to inspect a
/// collision before it goes to the solver.
/// Notes:
/// - this function must be thread-safe
/// - this is only called if the shape has enabled pre-solve events
/// - this may be called for awake dynamic bodies and sensors
/// - this is not called for sensors
/// Return false if you want to disable the contact this step
/// This has limited information because it is used during CCD which does not have the
/// full contact manifold.
/// @warning Do not attempt to modify the world inside this callback
/// @ingroup world
pub const b3PreSolveFcn = fn (shapeIdA: b3ShapeId, shapeIdB: b3ShapeId, point: b3Pos, normal: b3Vec3, context: ?*anyopaque) callconv(.c) bool;
/// Prototype callback for overlap queries.
/// Called for each shape found in the query.
/// @see b3World_OverlapAABB
/// @return false to terminate the query.
/// @ingroup world
pub const b3OverlapResultFcn = fn (shapeId: b3ShapeId, context: ?*anyopaque) callconv(.c) bool;
/// Prototype callback for ray casts.
/// Called for each shape found in the query. You control how the ray cast
/// proceeds by returning a float:
/// return -1: ignore this shape and continue
/// return 0: terminate the ray cast
/// return fraction: clip the ray to this point
/// return 1: don't clip the ray and continue
/// @param shapeId the shape hit by the ray
/// @param point the point of initial intersection
/// @param normal the normal vector at the point of intersection
/// @param fraction the fraction along the ray at the point of intersection
/// @param userMaterialId the shape or triangle surface type
/// @param triangleIndex the triangle index for mesh or height field shapes or -1 for other shape types
/// @param childIndex the child shape index for compound shapes
/// @param context the user context
/// @return -1 to filter, 0 to terminate, fraction to clip the ray for closest hit, 1 to continue
/// @see b3World_CastRay
/// @ingroup world
pub const b3CastResultFcn = fn (shapeId: b3ShapeId, point: b3Pos, normal: b3Vec3, fraction: f32, userMaterialId: u64, triangleIndex: c_int, childIndex: c_int, context: ?*anyopaque) callconv(.c) f32;
pub const struct_b3Capacity = extern struct {
    /// Number of expected static shapes.
    staticShapeCount: c_int = 0,
    /// Number of expected dynamic and kinematic shapes.
    dynamicShapeCount: c_int = 0,
    /// Number of expected static bodies.
    staticBodyCount: c_int = 0,
    /// Number of expected dynamic and kinematic bodies.
    dynamicBodyCount: c_int = 0,
    /// Number of expected contacts.
    contactCount: c_int = 0,
};
/// Optional world capacities that can be use to avoid run-time allocations
/// @ingroup world
pub const b3Capacity = struct_b3Capacity;
pub const struct_b3WorldDef = extern struct {
    /// Gravity vector. Box3D has no up-vector defined.
    gravity: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Restitution speed threshold, usually in m/s. Collisions above this
    /// speed have restitution applied (will bounce).
    restitutionThreshold: f32 = 0,
    /// Hit event speed threshold, usually in m/s. Collisions above this
    /// speed can generate hit events if the shape also enables hit events.
    hitEventThreshold: f32 = 0,
    /// Contact stiffness. Cycles per second. Increasing this increases the speed of overlap recovery, but can introduce jitter.
    contactHertz: f32 = 0,
    /// Contact bounciness. Non-dimensional. You can speed up overlap recovery by decreasing this with
    /// the trade-off that overlap resolution becomes more energetic.
    contactDampingRatio: f32 = 0,
    /// This parameter controls how fast overlap is resolved and usually has units of meters per second. This only
    /// puts a cap on the resolution speed. The resolution speed is increased by increasing the hertz and/or
    /// decreasing the damping ratio.
    contactSpeed: f32 = 0,
    /// Maximum linear speed. Usually meters per second.
    maximumLinearSpeed: f32 = 0,
    /// Optional mixing callback for friction. The default uses sqrt(frictionA * frictionB).
    frictionCallback: ?*const b3FrictionCallback = null,
    /// Optional mixing callback for restitution. The default uses max(restitutionA, restitutionB).
    restitutionCallback: ?*const b3RestitutionCallback = null,
    /// Can bodies go to sleep to improve performance
    enableSleep: bool = false,
    /// Enable continuous collision
    enableContinuous: bool = false,
    /// Number of workers to use with the provided task system. Box3D performs best when using only
    /// performance cores and accessing a single L2 cache. Efficiency cores and hyper-threading provide
    /// little benefit and may even harm performance.
    /// This is clamped to the range [1, B3_MAX_WORKERS]. Using a value above 1 will turn on multithreading.
    /// If task callbacks are provided then Box3D will use the user provided task system. Otherwise Box3D
    /// will create threads and use an internal scheduler.
    workerCount: u32 = 0,
    /// function to spawn task
    enqueueTask: ?*const b3EnqueueTaskCallback = null,
    /// function to finish a task
    finishTask: ?*const b3FinishTaskCallback = null,
    /// User context that is provided to enqueueTask and finishTask
    userTaskContext: ?*anyopaque = null,
    /// User data associated with a world
    userData: ?*anyopaque = null,
    /// Used to create debug draw shapes. This is called when a shape is
    /// first drawn using b3DebugDraw.
    createDebugShape: ?*const b3CreateDebugShapeCallback = null,
    /// Used to destroy debug draw shapes. This is called when a shape is modified or destroyed.
    destroyDebugShape: ?*const b3DestroyDebugShapeCallback = null,
    /// This is passed to the debug shape callbacks to provide a user context.
    userDebugShapeContext: ?*anyopaque = null,
    /// Optional initial capacities
    capacity: b3Capacity = @import("std").mem.zeroes(b3Capacity),
    /// Used internally to detect a valid definition. DO NOT SET.
    internalValue: c_int = 0,
    /// Create a world for rigid body simulation. A world contains bodies, shapes, and constraints. You may create
    /// up to 128 worlds. Each world is completely independent and may be simulated in parallel.
    /// @return the world id.
    pub const b3CreateWorld = __root.b3CreateWorld;
};
/// World definition used to create a simulation world. Must be initialized using b3DefaultWorldDef.
/// @ingroup world
pub const b3WorldDef = struct_b3WorldDef;
/// Use this to initialize your world definition
/// @ingroup world
pub extern fn b3DefaultWorldDef() b3WorldDef;
/// zero mass, zero velocity, may be manually moved
pub const b3_staticBody: c_int = 0;
/// zero mass, velocity set by user, moved by solver
pub const b3_kinematicBody: c_int = 1;
/// positive mass, velocity determined by forces, moved by solver
pub const b3_dynamicBody: c_int = 2;
/// number of body types
pub const b3_bodyTypeCount: c_int = 3;
pub const enum_b3BodyType = c_uint;
/// The body simulation type.
/// Each body is one of these three types. The type determines how the body behaves in the simulation.
/// @ingroup body
pub const b3BodyType = enum_b3BodyType;
pub const struct_b3MotionLocks = extern struct {
    /// Prevent translation along the x-axis
    linearX: bool = false,
    /// Prevent translation along the y-axis
    linearY: bool = false,
    /// Prevent translation along the z-axis
    linearZ: bool = false,
    /// Prevent rotation around the x-axis
    angularX: bool = false,
    /// Prevent rotation around the y-axis
    angularY: bool = false,
    /// Prevent rotation around the z-axis
    angularZ: bool = false,
};
/// Motion locks to restrict the body movement
/// @ingroup body
pub const b3MotionLocks = struct_b3MotionLocks;
pub const struct_b3BodyDef = extern struct {
    /// The body type: static, kinematic, or dynamic.
    type: b3BodyType = @import("std").mem.zeroes(b3BodyType),
    /// The initial world position of the body. Bodies should be created with the desired position.
    /// @note Creating bodies at the origin and then moving them nearly doubles the cost of body creation, especially
    /// if the body is moved after shapes have been added.
    position: b3Pos = @import("std").mem.zeroes(b3Pos),
    /// The initial world rotation of the body.
    rotation: b3Quat = @import("std").mem.zeroes(b3Quat),
    /// The initial linear velocity of the body's origin. Usually in meters per second.
    linearVelocity: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The initial angular velocity of the body. Radians per second.
    angularVelocity: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Linear damping is used to reduce the linear velocity. The damping parameter
    /// can be larger than 1 but the damping effect becomes sensitive to the
    /// time step when the damping parameter is large.
    /// Generally linear damping is undesirable because it makes objects move slowly
    /// as if they are floating.
    linearDamping: f32 = 0,
    /// Angular damping is used to reduce the angular velocity. The damping parameter
    /// can be larger than 1.0f but the damping effect becomes sensitive to the
    /// time step when the damping parameter is large.
    /// Angular damping can be used to slow down rotating bodies.
    angularDamping: f32 = 0,
    /// Scale the gravity applied to this body. Non-dimensional.
    gravityScale: f32 = 0,
    /// Sleep speed threshold, default is 0.05 meters per second
    sleepThreshold: f32 = 0,
    /// Optional body name for debugging.
    name: [*c]const u8 = null,
    /// Use this to store application specific body data.
    userData: ?*anyopaque = null,
    /// Motions locks to restrict linear and angular movement
    motionLocks: b3MotionLocks = @import("std").mem.zeroes(b3MotionLocks),
    /// Set this flag to false if this body should never fall asleep.
    enableSleep: bool = false,
    /// Is this body initially awake or sleeping?
    isAwake: bool = false,
    /// Treat this body as a high speed object that performs continuous collision detection
    /// against dynamic and kinematic bodies, but not other bullet bodies.
    /// @warning Bullets should be used sparingly. They are not a solution for general dynamic-versus-dynamic
    /// continuous collision. They do not guarantee accurate collision if both bodies are fast moving because
    /// the bullet does a continuous check after all non-bullet bodies have moved. You could get unlucky and have
    /// the bullet body end a time step very close to a non-bullet body and the non-bullet body then moves over
    /// the bullet body. In continuous collision, initial overlap is ignored to avoid freezing bodies in place.
    /// I do not recommend using them for game projectiles if precise collision timing is needed. Instead consider
    /// using a ray or shape cast. You can use a marching ray or shape cast for projectile that moves over time.
    /// If you want a fast moving projectile to collide with a fast moving target, you need to consider the relative
    /// movement in your ray or shape cast. This is out of the scope of Box3D.
    /// So what are good use cases for bullets? Pinball games or games with dynamic containers that hold other objects.
    /// It should be a use case where it doesn't break the game if there is a collision missed, but having them
    /// captured improves the quality of the game.
    isBullet: bool = false,
    /// Used to disable a body. A disabled body does not move or collide.
    isEnabled: bool = false,
    /// This allows this body to bypass rotational speed limits. Should only be used
    /// for circular objects, like wheels.
    allowFastRotation: bool = false,
    /// Enable contact recycling. True by default. Leaving this enabled improves performance
    /// but may lead to ghost collision that should be avoided on characters.
    enableContactRecycling: bool = false,
    /// Used internally to detect a valid definition. DO NOT SET.
    internalValue: c_int = 0,
};
/// A body definition holds all the data needed to construct a rigid body.
/// You can safely re-use body definitions. Shapes are added to a body after construction.
/// Body definitions are temporary objects used to bundle creation parameters.
/// Must be initialized using b3DefaultBodyDef().
/// @ingroup body
pub const b3BodyDef = struct_b3BodyDef;
/// Use this to initialize your body definition
/// @ingroup body
pub extern fn b3DefaultBodyDef() b3BodyDef;
pub const struct_b3Filter = extern struct {
    /// The collision category bits. Normally you would just set one bit. The category bits should
    /// represent your application object types. For example:
    /// @code{.cpp}
    /// enum MyCategories
    /// {
    ///    Static  = 0x00000001,
    ///    Dynamic = 0x00000002,
    ///    Debris  = 0x00000004,
    ///    Player  = 0x00000008,
    ///    // etc
    /// };
    /// @endcode
    categoryBits: u64 = 0,
    /// The collision mask bits. This states the categories that this
    /// shape would accept for collision.
    /// For example, you may want your player to only collide with static objects
    /// and other players.
    /// @code{.c}
    /// maskBits = Static | Player;
    /// @endcode
    maskBits: u64 = 0,
    /// Collision groups allow a certain group of objects to never collide (negative)
    /// or always collide (positive). A group index of zero has no effect. Non-zero group filtering
    /// always wins against the mask bits.
    /// For example, you may want ragdolls to collide with other ragdolls but you don't want
    /// ragdoll self-collision. In this case you would give each ragdoll a unique negative group index
    /// and apply that group index to all shapes on the ragdoll.
    groupIndex: c_int = 0,
};
/// This is used to filter collision on shapes. It affects shape-vs-shape collision
/// and shape-versus-query collision (such as b3World_CastRay).
/// @ingroup shape
pub const b3Filter = struct_b3Filter;
/// Use this to initialize your filter
/// @ingroup shape
pub extern fn b3DefaultFilter() b3Filter;
pub const struct_b3SurfaceMaterial = extern struct {
    /// The Coulomb (dry) friction coefficient, usually in the range [0,1].
    friction: f32 = 0,
    /// The coefficient of restitution (bounce) usually in the range [0,1].
    /// https://en.wikipedia.org/wiki/Coefficient_of_restitution
    restitution: f32 = 0,
    /// The rolling resistance usually in the range [0,1]. This is only used for spheres and capsules.
    rollingResistance: f32 = 0,
    /// The tangent velocity for conveyor belts. This is local to the shape and will be projected
    /// onto the contact surface.
    tangentVelocity: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// User material identifier. This is passed with query results and to friction and restitution
    /// combining functions. It is not used internally.
    userMaterialId: u64 = 0,
    /// Custom debug draw color. Ignored if 0. The low 24 bits are RGB. The high byte may
    /// carry a b3DebugMaterial preset, see b3MakeDebugColor.
    /// @see b3HexColor
    customColor: u32 = 0,
    /// Explicit padding. Must be zero.
    padding: u32 = 0,
};
/// Material properties supported per triangle on meshes and height fields
/// @ingroup shape
pub const b3SurfaceMaterial = struct_b3SurfaceMaterial;
/// Use this to initialize your surface material
/// @ingroup shape
pub extern fn b3DefaultSurfaceMaterial() b3SurfaceMaterial;
pub const struct_b3ShapeDef = extern struct {
    /// Optional shape name for debugging
    name: [*c]const u8 = null,
    /// Use this to store application specific shape data.
    userData: ?*anyopaque = null,
    /// Surface material used on mesh shapes per triangle. Ignored for convex shapes. Ignored for compound shapes.
    materials: [*c]b3SurfaceMaterial = null,
    /// Surface material count.
    materialCount: c_int = 0,
    /// The base surface material. Ignored for compound shapes.
    baseMaterial: b3SurfaceMaterial = @import("std").mem.zeroes(b3SurfaceMaterial),
    /// The density, usually in kg/m^3.
    density: f32 = 0,
    /// Explosion scale for b3World_Explode. non-dimensional
    explosionScale: f32 = 0,
    /// Contact filtering data.
    filter: b3Filter = @import("std").mem.zeroes(b3Filter),
    /// Enable custom filtering. Only one of the two shapes needs to enable custom filtering. See b3WorldDef.
    enableCustomFiltering: bool = false,
    /// A sensor shape generates overlap events but never generates a collision response.
    /// Sensors do not have continuous collision. Instead, use a ray or shape cast for those scenarios.
    /// Sensors still contribute to the body mass if they have non-zero density.
    /// @note Sensor events are disabled by default.
    /// @see enableSensorEvents
    isSensor: bool = false,
    /// Enable sensor events for this shape. This applies to sensors and non-sensors. False by default, even for sensors.
    /// Only convex shapes may act as sensor visitors.
    enableSensorEvents: bool = false,
    /// Enable contact events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors. False by default.
    enableContactEvents: bool = false,
    /// Enable hit events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors. False by default.
    enableHitEvents: bool = false,
    /// Enable pre-solve contact events for this shape. Only applies to dynamic bodies. These are expensive
    /// and must be carefully handled due to multithreading. Ignored for sensors.
    enablePreSolveEvents: bool = false,
    /// When shapes are created they will scan the environment for collision the next time step. This can significantly slow down
    /// static body creation when there are many static shapes.
    /// This is flag is ignored for dynamic and kinematic shapes which always invoke contact creation.
    invokeContactCreation: bool = false,
    /// Should the body update the mass properties when this shape is created. Default is true.
    /// Warning: if this is false, you MUST call b3Body_ApplyMassFromShapes or b3Body_SetMassData before simulating the world.
    updateBodyMass: bool = false,
    /// Enable speculative collision. Leave this true unless you care about reducing ghost collision
    /// more than continuous collision under rotation.
    /// Experimental: this can only disable speculative contact between hulls and triangles (meshes and height fields).
    enableSpeculativeContact: bool = false,
    /// Used internally to detect a valid definition. DO NOT SET.
    internalValue: c_int = 0,
};
/// Used to create a shape
/// @ingroup shape
pub const b3ShapeDef = struct_b3ShapeDef;
/// Use this to initialize your shape definition
/// @ingroup shape
pub extern fn b3DefaultShapeDef() b3ShapeDef;
pub const struct_b3Profile = extern struct {
    step: f32 = 0,
    pairs: f32 = 0,
    collide: f32 = 0,
    solve: f32 = 0,
    solverSetup: f32 = 0,
    constraints: f32 = 0,
    prepareConstraints: f32 = 0,
    integrateVelocities: f32 = 0,
    warmStart: f32 = 0,
    solveImpulses: f32 = 0,
    integratePositions: f32 = 0,
    relaxImpulses: f32 = 0,
    applyRestitution: f32 = 0,
    storeImpulses: f32 = 0,
    splitIslands: f32 = 0,
    transforms: f32 = 0,
    sensorHits: f32 = 0,
    jointEvents: f32 = 0,
    hitEvents: f32 = 0,
    refit: f32 = 0,
    bullets: f32 = 0,
    sleepIslands: f32 = 0,
    sensors: f32 = 0,
};
/// Profiling data. Times are in milliseconds.
/// @ingroup world
pub const b3Profile = struct_b3Profile;
pub const struct_b3Counters = extern struct {
    bodyCount: c_int = 0,
    shapeCount: c_int = 0,
    contactCount: c_int = 0,
    jointCount: c_int = 0,
    islandCount: c_int = 0,
    stackUsed: c_int = 0,
    arenaCapacity: c_int = 0,
    staticTreeHeight: c_int = 0,
    treeHeight: c_int = 0,
    satCallCount: c_int = 0,
    satCacheHitCount: c_int = 0,
    byteCount: c_int = 0,
    taskCount: c_int = 0,
    colorCounts: [24]c_int = @import("std").mem.zeroes([24]c_int),
    manifoldCounts: [8]c_int = @import("std").mem.zeroes([8]c_int),
    /// Number of contacts touched by the collide pass
    /// graph contacts + awake-set non-touching
    awakeContactCount: c_int = 0,
    /// Number of contacts recycled in the most recent step.
    recycledContactCount: c_int = 0,
    /// Maximum number of time of impact iterations
    distanceIterations: c_int = 0,
    pushBackIterations: c_int = 0,
    rootIterations: c_int = 0,
};
/// Counters that give details of the simulation size.
/// @ingroup world
pub const b3Counters = struct_b3Counters;
pub const b3_parallelJoint: c_int = 0;
pub const b3_distanceJoint: c_int = 1;
pub const b3_filterJoint: c_int = 2;
pub const b3_motorJoint: c_int = 3;
pub const b3_prismaticJoint: c_int = 4;
pub const b3_revoluteJoint: c_int = 5;
pub const b3_sphericalJoint: c_int = 6;
pub const b3_weldJoint: c_int = 7;
pub const b3_wheelJoint: c_int = 8;
pub const enum_b3JointType = c_uint;
/// Joint type enumeration. This is useful because all joint types use b3JointId and sometimes you
/// want to get the type of a joint.
/// @ingroup joint
pub const b3JointType = enum_b3JointType;
pub const struct_b3JointDef = extern struct {
    /// User data pointer
    userData: ?*anyopaque = null,
    /// The first attached body
    bodyIdA: b3BodyId = @import("std").mem.zeroes(b3BodyId),
    /// The second attached body
    bodyIdB: b3BodyId = @import("std").mem.zeroes(b3BodyId),
    /// The first local joint frame
    localFrameA: b3Transform = @import("std").mem.zeroes(b3Transform),
    /// The second local joint frame
    localFrameB: b3Transform = @import("std").mem.zeroes(b3Transform),
    /// Force threshold for joint events
    forceThreshold: f32 = 0,
    /// Torque threshold for joint events
    torqueThreshold: f32 = 0,
    /// Constraint hertz (advanced feature)
    constraintHertz: f32 = 0,
    /// Constraint damping ratio (advanced feature)
    constraintDampingRatio: f32 = 0,
    /// Debug draw scale
    drawScale: f32 = 0,
    /// Set this flag to true if the attached bodies should collide
    collideConnected: bool = false,
    /// Used internally to detect a valid definition. DO NOT SET.
    internalValue: c_int = 0,
};
/// Base joint definition used by all joint types. The local frames are measured from the
/// body's origin rather than the center of mass because:
/// 1. You might not know where the center of mass will be.
/// 2. If you add/remove shapes from a body and recompute the mass, the joints will be broken.
/// @ingroup joint
pub const b3JointDef = struct_b3JointDef;
pub const struct_b3DistanceJointDef = extern struct {
    /// Base joint definition
    base: b3JointDef = @import("std").mem.zeroes(b3JointDef),
    /// The rest length of this joint. Clamped to a stable minimum value.
    length: f32 = 0,
    /// Enable the distance constraint to behave like a spring. If false
    /// then the distance joint will be rigid, overriding the limit and motor.
    enableSpring: bool = false,
    /// The lower spring force controls how much tension it can sustain
    lowerSpringForce: f32 = 0,
    /// The upper spring force controls how much compression it can sustain
    upperSpringForce: f32 = 0,
    /// The spring linear stiffness Hertz, cycles per second
    hertz: f32 = 0,
    /// The spring linear damping ratio, non-dimensional
    dampingRatio: f32 = 0,
    /// Enable/disable the joint limit
    enableLimit: bool = false,
    /// Minimum length. Clamped to a stable minimum value.
    minLength: f32 = 0,
    /// Maximum length. Must be greater than or equal to the minimum length.
    maxLength: f32 = 0,
    /// Enable/disable the joint motor
    enableMotor: bool = false,
    /// The maximum motor force, usually in newtons
    maxMotorForce: f32 = 0,
    /// The desired motor speed, usually in meters per second
    motorSpeed: f32 = 0,
};
/// Distance joint definition.
/// Connects a point on body A with a point on body B by a segment.
/// Useful for ropes and springs.
/// @ingroup distance_joint
pub const b3DistanceJointDef = struct_b3DistanceJointDef;
/// Use this to initialize your joint definition
/// @ingroup distance_joint
pub extern fn b3DefaultDistanceJointDef() b3DistanceJointDef;
pub const struct_b3MotorJointDef = extern struct {
    /// Base joint definition
    base: b3JointDef = @import("std").mem.zeroes(b3JointDef),
    /// The desired linear velocity
    linearVelocity: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The maximum motor force in newtons
    maxVelocityForce: f32 = 0,
    /// The desired angular velocity
    angularVelocity: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The maximum motor torque in newton-meters
    maxVelocityTorque: f32 = 0,
    /// Linear spring hertz for position control
    linearHertz: f32 = 0,
    /// Linear spring damping ratio
    linearDampingRatio: f32 = 0,
    /// Maximum spring force in newtons
    maxSpringForce: f32 = 0,
    /// Angular spring hertz for position control
    angularHertz: f32 = 0,
    /// Angular spring damping ratio
    angularDampingRatio: f32 = 0,
    /// Maximum spring torque in newton-meters
    maxSpringTorque: f32 = 0,
};
/// A motor joint is used to control the relative position and velocity between two bodies.
/// @ingroup motor_joint
pub const b3MotorJointDef = struct_b3MotorJointDef;
/// Use this to initialize your joint definition
/// @ingroup motor_joint
pub extern fn b3DefaultMotorJointDef() b3MotorJointDef;
pub const struct_b3FilterJointDef = extern struct {
    /// Base joint definition
    base: b3JointDef = @import("std").mem.zeroes(b3JointDef),
};
/// A filter joint is used to disable collision between two specific bodies.
/// @ingroup filter_joint
pub const b3FilterJointDef = struct_b3FilterJointDef;
/// Use this to initialize your joint definition
/// @ingroup filter_joint
pub extern fn b3DefaultFilterJointDef() b3FilterJointDef;
pub const struct_b3ParallelJointDef = extern struct {
    /// Base joint definition
    base: b3JointDef = @import("std").mem.zeroes(b3JointDef),
    /// The spring stiffness Hertz, cycles per second
    hertz: f32 = 0,
    /// The spring damping ratio, non-dimensional
    dampingRatio: f32 = 0,
    /// The maximum spring torque, typically in newton-meters.
    maxTorque: f32 = 0,
};
/// Parallel joint definition. Constrains the angle between axis z in body A and axis z in body B
/// using a spring. Useful to keep a body upright.
/// @ingroup parallel_joint
pub const b3ParallelJointDef = struct_b3ParallelJointDef;
/// Use this to initialize your joint definition
/// @ingroup parallel_joint
pub extern fn b3DefaultParallelJointDef() b3ParallelJointDef;
pub const struct_b3PrismaticJointDef = extern struct {
    /// Base joint definition
    base: b3JointDef = @import("std").mem.zeroes(b3JointDef),
    /// Enable a linear spring along the prismatic joint axis
    enableSpring: bool = false,
    /// The spring stiffness Hertz, cycles per second
    hertz: f32 = 0,
    /// The spring damping ratio, non-dimensional
    dampingRatio: f32 = 0,
    /// The target translation for the joint in meters. The spring-damper will drive
    /// to this translation.
    targetTranslation: f32 = 0,
    /// Enable/disable the joint limit
    enableLimit: bool = false,
    /// The lower translation limit
    lowerTranslation: f32 = 0,
    /// The upper translation limit
    upperTranslation: f32 = 0,
    /// Enable/disable the joint motor
    enableMotor: bool = false,
    /// The maximum motor force, typically in newtons
    maxMotorForce: f32 = 0,
    /// The desired motor speed, typically in meters per second
    motorSpeed: f32 = 0,
};
/// Prismatic joint definition. Body B may slide along the x-axis in local frame A.
/// Body B cannot rotate relative to body A. The joint translation is zero when the
/// local frame origins coincide in world space.
/// @ingroup prismatic_joint
pub const b3PrismaticJointDef = struct_b3PrismaticJointDef;
/// Use this to initialize your joint definition
/// @ingroup prismatic_joint
pub extern fn b3DefaultPrismaticJointDef() b3PrismaticJointDef;
pub const struct_b3RevoluteJointDef = extern struct {
    /// Base joint definition.
    base: b3JointDef = @import("std").mem.zeroes(b3JointDef),
    /// The bodyB angle minus bodyA angle in the reference state (radians).
    /// This defines the zero angle for the joint limit.
    targetAngle: f32 = 0,
    /// Enable a rotational spring on the revolute hinge axis.
    enableSpring: bool = false,
    /// The spring stiffness Hertz, cycles per second.
    hertz: f32 = 0,
    /// The spring damping ratio, non-dimensional.
    dampingRatio: f32 = 0,
    /// A flag to enable joint limits.
    enableLimit: bool = false,
    /// The lower angle for the joint limit in radians. Minimum of -0.99*pi radians.
    lowerAngle: f32 = 0,
    /// The upper angle for the joint limit in radians. Maximum of 0.99*pi radians.
    upperAngle: f32 = 0,
    /// A flag to enable the joint motor.
    enableMotor: bool = false,
    /// The maximum motor torque, typically in newton-meters.
    maxMotorTorque: f32 = 0,
    /// The desired motor speed in radians per second.
    motorSpeed: f32 = 0,
};
/// Revolute joint definition. A point on body B is fixed to a point on body A.
/// Allows relative rotation about the z-axis.
/// @ingroup revolute_joint
pub const b3RevoluteJointDef = struct_b3RevoluteJointDef;
/// Use this to initialize your joint definition.
/// @ingroup revolute_joint
pub extern fn b3DefaultRevoluteJointDef() b3RevoluteJointDef;
pub const struct_b3SphericalJointDef = extern struct {
    /// Base joint definition
    base: b3JointDef = @import("std").mem.zeroes(b3JointDef),
    /// Enable a rotational spring that attempts to align the two joint frames.
    enableSpring: bool = false,
    /// The spring stiffness Hertz, cycles per second. This may be clamped internally
    /// according to the time step to maintain stability. Non-negative number.
    hertz: f32 = 0,
    /// The spring damping ratio, non-dimensional. Non-negative number.
    dampingRatio: f32 = 0,
    /// Target spring rotation, joint frame B relative to joint frame A.
    targetRotation: b3Quat = @import("std").mem.zeroes(b3Quat),
    /// A flag to enable the cone limit. The cone is centered on the frameA z-axis.
    enableConeLimit: bool = false,
    /// The angle for the cone limit in radians. Valid range is [0, pi]
    coneAngle: f32 = 0,
    /// A flag to enable the twist limit. The twist is centered on the frameB z-axis.
    enableTwistLimit: bool = false,
    /// The angle for the lower twist limit in radians. Minimum of -0.99*pi radians.
    lowerTwistAngle: f32 = 0,
    /// The angle for the upper twist limit in radians. Maximum of 0.99*pi radians.
    upperTwistAngle: f32 = 0,
    /// A flag to enable the joint motor
    enableMotor: bool = false,
    /// The maximum motor torque, typically in newton-meters. Non-negative number.
    maxMotorTorque: f32 = 0,
    /// The desired motor angular velocity in radians per second.
    motorVelocity: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
};
/// Spherical joint definition. A point on body B is fixed to a point on body A.
/// Allows rotation about the shared point.
/// @ingroup spherical_joint
pub const b3SphericalJointDef = struct_b3SphericalJointDef;
/// Use this to initialize your joint definition.
/// @ingroup spherical_joint
pub extern fn b3DefaultSphericalJointDef() b3SphericalJointDef;
pub const struct_b3WeldJointDef = extern struct {
    /// Base joint definition
    base: b3JointDef = @import("std").mem.zeroes(b3JointDef),
    /// Linear stiffness expressed as Hertz (cycles per second). Use zero for maximum stiffness.
    linearHertz: f32 = 0,
    /// Angular stiffness as Hertz (cycles per second). Use zero for maximum stiffness.
    angularHertz: f32 = 0,
    /// Linear damping ratio, non-dimensional. Use 1 for critical damping.
    linearDampingRatio: f32 = 0,
    /// Linear damping ratio, non-dimensional. Use 1 for critical damping.
    angularDampingRatio: f32 = 0,
};
/// Weld joint definition
/// Connects two bodies together rigidly. This constraint provides springs to mimic
/// soft-body simulation.
/// @note The approximate solver in Box3D cannot hold many bodies together rigidly
/// @ingroup weld_joint
pub const b3WeldJointDef = struct_b3WeldJointDef;
/// Use this to initialize your joint definition
/// @ingroup weld_joint
pub extern fn b3DefaultWeldJointDef() b3WeldJointDef;
pub const struct_b3WheelJointDef = extern struct {
    /// Base joint definition
    base: b3JointDef = @import("std").mem.zeroes(b3JointDef),
    /// Enable a linear spring along the local axis
    enableSuspensionSpring: bool = false,
    /// Spring stiffness in Hertz
    suspensionHertz: f32 = 0,
    /// Spring damping ratio, non-dimensional
    suspensionDampingRatio: f32 = 0,
    /// Enable/disable the joint linear limit
    enableSuspensionLimit: bool = false,
    /// The lower suspension translation limit
    lowerSuspensionLimit: f32 = 0,
    /// The upper translation limit
    upperSuspensionLimit: f32 = 0,
    /// Enable/disable the joint rotational motor
    enableSpinMotor: bool = false,
    /// The maximum motor torque, typically in newton-meters
    maxSpinTorque: f32 = 0,
    /// The desired motor speed in radians per second
    spinSpeed: f32 = 0,
    /// Enable steering, otherwise the steering is fixed forward
    enableSteering: bool = false,
    /// Steering stiffness in Hertz
    steeringHertz: f32 = 0,
    /// Spring damping ratio, non-dimensional
    steeringDampingRatio: f32 = 0,
    /// The target steering angle in radians
    targetSteeringAngle: f32 = 0,
    /// The maximum steering torque in N*m
    maxSteeringTorque: f32 = 0,
    /// Enable/disable the steering angular limit
    enableSteeringLimit: bool = false,
    /// The lower steering angle in radians
    lowerSteeringLimit: f32 = 0,
    /// The upper steering angle in radians
    upperSteeringLimit: f32 = 0,
};
/// Wheel joint definition
/// Body A is the chassis and body B is the wheel.
/// The wheel rotates around the local z-axis in frame B.
/// The wheel translates along the local x-axis in frame A.
/// The wheel can optionally steer along the x-axis in frame A.
/// @ingroup wheel_joint
pub const b3WheelJointDef = struct_b3WheelJointDef;
/// Use this to initialize your joint definition
/// @ingroup wheel_joint
pub extern fn b3DefaultWheelJointDef() b3WheelJointDef;
pub const struct_b3ExplosionDef = extern struct {
    /// Mask bits to filter shapes
    maskBits: u64 = 0,
    /// The center of the explosion in world space
    position: b3Pos = @import("std").mem.zeroes(b3Pos),
    /// The radius of the explosion
    radius: f32 = 0,
    /// The falloff distance beyond the radius. Impulse is reduced to zero at this distance.
    falloff: f32 = 0,
    /// Impulse per unit area. This applies an impulse according to the shape area that
    /// is facing the explosion. Explosions only apply to spheres, capsules, and hulls. This
    /// may be negative for implosions.
    impulsePerArea: f32 = 0,
};
/// The explosion definition is used to configure options for explosions. Explosions
/// consider shape geometry when computing the impulse.
/// @ingroup world
pub const b3ExplosionDef = struct_b3ExplosionDef;
/// Use this to initialize your explosion definition
/// @ingroup world
pub extern fn b3DefaultExplosionDef() b3ExplosionDef;
pub const struct_b3SensorBeginTouchEvent = extern struct {
    /// The id of the sensor shape
    sensorShapeId: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// The id of the shape that began touching the sensor shape
    visitorShapeId: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
};
/// A begin-touch event is generated when a shape starts to overlap a sensor shape.
pub const b3SensorBeginTouchEvent = struct_b3SensorBeginTouchEvent;
pub const struct_b3SensorEndTouchEvent = extern struct {
    /// The id of the sensor shape
    /// @warning this shape may have been destroyed
    /// @see b3Shape_IsValid
    sensorShapeId: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// The id of the shape that stopped touching the sensor shape
    /// @warning this shape may have been destroyed
    /// @see b3Shape_IsValid
    visitorShapeId: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
};
/// An end touch event is generated when a shape stops overlapping a sensor shape.
/// These include things like setting the transform, destroying a body or shape, or changing
/// a filter. You will also get an end event if the sensor or visitor are destroyed.
/// Therefore you should always confirm the shape id is valid using b3Shape_IsValid.
pub const b3SensorEndTouchEvent = struct_b3SensorEndTouchEvent;
pub const struct_b3SensorEvents = extern struct {
    /// Array of sensor begin touch events
    beginEvents: [*c]b3SensorBeginTouchEvent = null,
    /// Array of sensor end touch events
    endEvents: [*c]b3SensorEndTouchEvent = null,
    /// The number of begin touch events
    beginCount: c_int = 0,
    /// The number of end touch events
    endCount: c_int = 0,
};
/// Sensor events are buffered in the world and are available
/// as begin/end overlap event arrays after the time step is complete.
/// Note: these may become invalid if bodies and/or shapes are destroyed
pub const b3SensorEvents = struct_b3SensorEvents;
pub const struct_b3ContactBeginTouchEvent = extern struct {
    /// Id of the first shape
    shapeIdA: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// Id of the second shape
    shapeIdB: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// The transient contact id. This contact may be destroyed automatically when the world is modified or simulated.
    /// Use b3Contact_IsValid before using this id.
    contactId: b3ContactId = @import("std").mem.zeroes(b3ContactId),
};
/// A begin-touch event is generated when two shapes begin touching.
pub const b3ContactBeginTouchEvent = struct_b3ContactBeginTouchEvent;
pub const struct_b3ContactEndTouchEvent = extern struct {
    /// Id of the first shape
    /// @warning this shape may have been destroyed
    /// @see b3Shape_IsValid
    shapeIdA: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// Id of the first shape
    /// @warning this shape may have been destroyed
    /// @see b3Shape_IsValid
    shapeIdB: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// Id of the contact.
    /// @warning this contact may have been destroyed
    /// @see b3Contact_IsValid
    contactId: b3ContactId = @import("std").mem.zeroes(b3ContactId),
};
/// An end touch event is generated when two shapes stop touching.
/// You will get an end event if you do anything that destroys contacts previous to the last
/// world step. These include things like setting the transform, destroying a body
/// or shape, or changing a filter or body type.
pub const b3ContactEndTouchEvent = struct_b3ContactEndTouchEvent;
pub const struct_b3ContactHitEvent = extern struct {
    /// Id of the first shape
    shapeIdA: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// Id of the second shape
    shapeIdB: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// Id of the contact.
    /// @warning this contact may have been destroyed
    /// @see b3Contact_IsValid
    contactId: b3ContactId = @import("std").mem.zeroes(b3ContactId),
    /// Point where the shapes hit at the beginning of the time step.
    /// This is a mid-point between the two surfaces. It could be at speculative
    /// point where the two shapes were not touching at the beginning of the time step.
    point: b3Pos = @import("std").mem.zeroes(b3Pos),
    /// Normal vector pointing from shape A to shape B
    normal: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The speed the shapes are approaching. Always positive. Typically in meters per second.
    approachSpeed: f32 = 0,
    /// User material on shape A
    userMaterialIdA: u64 = 0,
    /// User material on shape B
    userMaterialIdB: u64 = 0,
};
/// A hit touch event is generated when two shapes collide with a speed faster than the hit speed threshold.
/// This may be reported for speculative contacts that have a confirmed impulse.
pub const b3ContactHitEvent = struct_b3ContactHitEvent;
pub const struct_b3ContactEvents = extern struct {
    /// Array of begin touch events
    beginEvents: [*c]b3ContactBeginTouchEvent = null,
    /// Array of end touch events
    endEvents: [*c]b3ContactEndTouchEvent = null,
    /// Array of hit events
    hitEvents: [*c]b3ContactHitEvent = null,
    /// Number of begin touch events
    beginCount: c_int = 0,
    /// Number of end touch events
    endCount: c_int = 0,
    /// Number of hit events
    hitCount: c_int = 0,
};
/// Contact events are buffered in the world and are available
/// as event arrays after the time step is complete.
/// Note: these may become invalid if bodies and/or shapes are destroyed
pub const b3ContactEvents = struct_b3ContactEvents;
pub const struct_b3BodyMoveEvent = extern struct {
    /// The body user data.
    userData: ?*anyopaque = null,
    /// The body transform.
    transform: b3WorldTransform = @import("std").mem.zeroes(b3WorldTransform),
    /// The body id.
    bodyId: b3BodyId = @import("std").mem.zeroes(b3BodyId),
    /// Did the body fall asleep this time step?
    fellAsleep: bool = false,
};
/// Body move events triggered when a body moves.
/// Triggered when a body moves due to simulation. Not reported for bodies moved by the user.
/// This also has a flag to indicate that the body went to sleep so the application can also
/// sleep that actor/entity/object associated with the body.
/// On the other hand if the flag does not indicate the body went to sleep then the application
/// can treat the actor/entity/object associated with the body as awake.
/// This is an efficient way for an application to update game object transforms rather than
/// calling functions such as b3Body_GetTransform() because this data is delivered as a contiguous array
/// and it is only populated with bodies that have moved.
/// @note If sleeping is disabled all dynamic and kinematic bodies will trigger move events.
pub const b3BodyMoveEvent = struct_b3BodyMoveEvent;
pub const struct_b3BodyEvents = extern struct {
    /// Array of move events
    moveEvents: [*c]b3BodyMoveEvent = null,
    /// Number of move events
    moveCount: c_int = 0,
};
/// Body events are buffered in the world and are available
/// as event arrays after the time step is complete.
/// Note: this data becomes invalid if bodies are destroyed
pub const b3BodyEvents = struct_b3BodyEvents;
pub const struct_b3JointEvent = extern struct {
    /// The joint id
    jointId: b3JointId = @import("std").mem.zeroes(b3JointId),
    /// The user data from the joint for convenience
    userData: ?*anyopaque = null,
};
/// Joint events report joints that are awake and have a force and/or torque exceeding the threshold
/// The observed forces and torques are not returned for efficiency reasons.
pub const b3JointEvent = struct_b3JointEvent;
pub const struct_b3JointEvents = extern struct {
    /// Array of events
    jointEvents: [*c]b3JointEvent = null,
    /// Number of events
    count: c_int = 0,
};
/// Joint events are buffered in the world and are available
/// as event arrays after the time step is complete.
/// Note: this data becomes invalid if joints are destroyed
pub const b3JointEvents = struct_b3JointEvents;
pub const struct_b3ManifoldPoint = extern struct {
    /// Location of the contact point relative to the bodyA center of mass in world space.
    anchorA: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Location of the contact point relative to the bodyB center of mass in world space.
    anchorB: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The separation of the contact point, negative if penetrating
    separation: f32 = 0,
    /// Cached separation used for contact recycling
    baseSeparation: f32 = 0,
    /// The impulse along the manifold normal vector. Since Box3D uses sub-stepping, this is
    /// result from the final sub-step.
    normalImpulse: f32 = 0,
    /// The total normal impulse applied during sub-stepping. This is important
    /// to identify speculative contact points that had an interaction in the time step.
    totalNormalImpulse: f32 = 0,
    /// Relative normal velocity pre-solve. Used for hit events. If the normal impulse is
    /// zero then there was no hit. Negative means shapes are approaching.
    normalVelocity: f32 = 0,
    /// Local point for matching
    /// Uniquely identifies a contact point between two shapes
    featureId: u32 = 0,
    /// Triangle index if one of the shapes is a mesh or height field
    triangleIndex: c_int = 0,
    /// Did this contact point exist in the previous step?
    persisted: bool = false,
};
/// A manifold point is a contact point belonging to a contact manifold.
/// It holds details related to the geometry and dynamics of the contact points.
/// Box3D uses speculative collision so some contact points may be separated.
/// You may use the maxNormalImpulse to determine if there was an interaction during
/// the time step.
pub const b3ManifoldPoint = struct_b3ManifoldPoint;
pub const struct_b3Manifold = extern struct {
    /// The manifold points. There may be 1 to 4 valid points.
    points: [4]b3ManifoldPoint = @import("std").mem.zeroes([4]b3ManifoldPoint),
    /// The unit normal vector in world space, points from shape A to shape B
    normal: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Central friction angular impulse (applied about the normal)
    twistImpulse: f32 = 0,
    /// Central friction linear impulse
    frictionImpulse: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Rolling resistance angular impulse
    rollingImpulse: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The number of contact points, will be 0 to 4
    pointCount: c_int = 0,
};
pub const struct_b3ContactData = extern struct {
    /// The contact id. You may hold onto this to track a contact across time steps.
    /// This id may become orphaned. Use b3Contact_IsValid before using it for other functions.
    contactId: b3ContactId = @import("std").mem.zeroes(b3ContactId),
    /// The first shape id.
    shapeIdA: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// The second shape id.
    shapeIdB: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// The contact manifold. This points to internal data and may become invalid. Do not store
    /// this pointer.
    manifolds: [*c]const struct_b3Manifold = null,
    /// The number of contact manifolds. For mesh and height-field collision there can be multiple manifolds.
    manifoldCount: c_int = 0,
};
/// The contact data for two shapes. By convention the manifold normal points
/// from shape A to shape B.
/// @see b3Shape_GetContactData() and b3Body_GetContactData()
pub const b3ContactData = struct_b3ContactData;
pub const struct_b3QueryFilter = extern struct {
    /// The collision category bits of this query. Normally you would just set one bit.
    categoryBits: u64 = 0,
    /// The collision mask bits. This states the shape categories that this
    /// query would accept for collision.
    maskBits: u64 = 0,
    /// Optional id combined with @ref name to identify this query in a recording, e.g. an entity id.
    /// Need not be unique on its own. 0 with a null name means untagged. Ignored when not recording.
    id: u64 = 0,
    /// Optional label combined with @ref id to identify this query, e.g. "bullet". Need not be unique
    /// on its own. The recorder hashes (id, name) into one stable key the viewer tracks the query by,
    /// so the same id and name pair identifies the same query across frames. NULL means none. Ignored
    /// when not recording.
    name: [*c]const u8 = null,
};
/// The query filter is used to filter collisions between queries and shapes. For example,
/// you may want a ray-cast representing a projectile to hit players and the static environment
/// but not debris.
pub const b3QueryFilter = struct_b3QueryFilter;
/// Use this to initialize your query filter
pub extern fn b3DefaultQueryFilter() b3QueryFilter;
pub const struct_b3RayCastInput = extern struct {
    /// Start point of the ray cast.
    origin: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Translation of the ray cast.
    /// end = start + translation.
    translation: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The maximum fraction of the translation to consider, typically 1
    maxFraction: f32 = 0,
    /// Use this to ensure your ray cast input is valid and avoid internal assertions.
    pub const b3IsValidRay = __root.b3IsValidRay;
};
/// Low level ray cast input data.
pub const b3RayCastInput = struct_b3RayCastInput;
pub const struct_b3RayResult = extern struct {
    /// The shape hit.
    shapeId: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// The world point of the hit.
    point: b3Pos = @import("std").mem.zeroes(b3Pos),
    /// The world normal of the shape surface at the hit point.
    normal: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The user material id at the hit point. This can be per triangle
    /// if the shape is a mesh, height-field, or compound with child mesh.
    userMaterialId: u64 = 0,
    /// The fraction of the input ray.
    fraction: f32 = 0,
    /// The triangle index if the shape is a mesh, height-field, or compound with
    /// child mesh.
    triangleIndex: c_int = 0,
    /// The child index if the shape is a compound.
    childIndex: c_int = 0,
    /// The number of BVH nodes visited. Diagnostic.
    nodeVisits: c_int = 0,
    /// The number of BVH leaves visited. Diagnostic.
    leafVisits: c_int = 0,
    /// Did the ray hit? If false, all other data is invalid.
    hit: bool = false,
};
/// Result from b3World_RayCastClosest.
pub const b3RayResult = struct_b3RayResult;
pub const struct_b3ShapeProxy = extern struct {
    /// The point cloud.
    points: [*c]const b3Vec3 = null,
    /// The number of points. Do not exceed B3_MAX_SHAPE_CAST_POINTS.
    count: c_int = 0,
    /// The external radius of the point cloud.
    radius: f32 = 0,
};
/// A shape proxy is used by the GJK algorithm. It can represent a convex shape.
pub const b3ShapeProxy = struct_b3ShapeProxy;
pub const struct_b3ShapeCastInput = extern struct {
    /// A generic query shape.
    proxy: b3ShapeProxy = @import("std").mem.zeroes(b3ShapeProxy),
    /// The translation of the shape cast.
    translation: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The maximum fraction of the translation to consider, typically 1.
    maxFraction: f32 = 0,
    /// Allow shape cast to encroach when initially touching. This only works if the radius is greater than zero.
    canEncroach: bool = false,
};
/// Low level shape cast input in generic form. This allows casting an arbitrary point
/// cloud wrap with a radius. For example, a sphere is a single point with a non-zero radius.
/// A capsule is two points with a non-zero radius. A box is four points with a zero radius.
pub const b3ShapeCastInput = struct_b3ShapeCastInput;
pub const struct_b3BoxCastInput = extern struct {
    /// The AABB to cast, in the tree's frame.
    box: b3AABB = @import("std").mem.zeroes(b3AABB),
    /// The sweep translation.
    translation: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The maximum fraction of the translation to consider, typically 1.
    maxFraction: f32 = 0,
};
/// Input for sweeping an AABB through a dynamic tree. The box is in the tree's world float frame.
/// The caller folds the cast shape radius and any world origin into the box, so the tree traversal
/// stays a conservative box sweep and the precise narrow phase happens per shape in the callback.
pub const b3BoxCastInput = struct_b3BoxCastInput;
pub const struct_b3CastOutput = extern struct {
    /// The surface normal at the hit point.
    normal: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The surface hit point.
    point: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The fraction of the input translation at collision.
    fraction: f32 = 0,
    /// The number of iterations used.
    iterations: c_int = 0,
    /// The index of the mesh or height field triangle hit.
    triangleIndex: c_int = 0,
    /// The index of the compound child shape.
    childIndex: c_int = 0,
    /// The material index. May be -1 for null.
    materialIndex: c_int = 0,
    /// Did the cast hit?
    hit: bool = false,
};
/// Low level ray cast or shape-cast output data.
pub const b3CastOutput = struct_b3CastOutput;
/// Ray cast or shape-cast output in world space. The hit point is a world position so the result
/// stays precise far from the world origin. Mirrors b3CastOutput with a double precision point.
pub const b3WorldCastOutput = b3CastOutput;
pub const struct_b3BodyCastResult = extern struct {
    /// The shape hit.
    shapeId: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// The world point on the shape surface.
    point: b3Pos = @import("std").mem.zeroes(b3Pos),
    /// The world normal vector on the shape surface.
    normal: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The fraction along the ray hit.
    /// hit point = origin + fraction * translation
    fraction: f32 = 0,
    /// The triangle index if the shape is a mesh or height-field.
    triangleIndex: c_int = 0,
    /// The user material id at the hit point. This can be per triangle
    /// if the shape is a mesh, height-field, or compound with child mesh.
    userMaterialId: u64 = 0,
    /// The number of iterations used. Diagnostic.
    iterations: c_int = 0,
    /// Did the cast hit? If false, all other fields are invalid.
    hit: bool = false,
};
/// Body cast result for ray and shape casts.
pub const b3BodyCastResult = struct_b3BodyCastResult;
pub const struct_b3SimplexCache = extern struct {
    /// Value use to compare length, area, volume of two simplexes.
    metric: f32 = 0,
    /// The number of stored simplex points
    count: u16 = 0,
    /// The cached simplex indices on shape A
    indexA: [4]u8 = @import("std").mem.zeroes([4]u8),
    /// The cached simplex indices on shape B
    indexB: [4]u8 = @import("std").mem.zeroes([4]u8),
};
/// Used to warm start the GJK simplex. If you call this function multiple times with nearby
/// transforms this might improve performance. Otherwise you can zero initialize this.
/// The distance cache must be initialized to zero on the first call.
/// Users should generally just zero initialize this structure for each call.
pub const b3SimplexCache = struct_b3SimplexCache;
pub const b3_emptyDistanceCache: b3SimplexCache = b3SimplexCache{
    .metric = @floatFromInt(@as(c_int, 0)),
    .count = 0,
    .indexA = @import("std").mem.zeroes([4]u8),
    .indexB = @import("std").mem.zeroes([4]u8),
};
pub const struct_b3ShapeCastPairInput = extern struct {
    /// The proxy for shape A
    proxyA: b3ShapeProxy = @import("std").mem.zeroes(b3ShapeProxy),
    /// The proxy for shape B
    proxyB: b3ShapeProxy = @import("std").mem.zeroes(b3ShapeProxy),
    /// Transform of shape B in shape A's frame, the relative pose B in A
    transform: b3Transform = @import("std").mem.zeroes(b3Transform),
    /// The translation of shape B, in A's frame
    translationB: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The fraction of the translation to consider, typically 1
    maxFraction: f32 = 0,
    /// Allows shapes with a radius to move slightly closer if already touching
    canEncroach: bool = false,
    /// Perform a linear shape cast of shape B moving and shape A fixed. Determines the hit point, normal, and translation fraction.
    /// The query runs in frame A, so the hit point and normal are returned in frame A. Initially touching shapes are a miss.
    pub const b3ShapeCast = __root.b3ShapeCast;
};
/// Input parameters for b3ShapeCast
pub const b3ShapeCastPairInput = struct_b3ShapeCastPairInput;
pub const struct_b3DistanceInput = extern struct {
    /// The proxy for shape A
    proxyA: b3ShapeProxy = @import("std").mem.zeroes(b3ShapeProxy),
    /// The proxy for shape B
    proxyB: b3ShapeProxy = @import("std").mem.zeroes(b3ShapeProxy),
    /// Transform of shape B in shape A's frame, the relative pose B in A
    /// (b3InvMulWorldTransforms( worldA, worldB )). The query is origin independent and runs in frame A.
    transform: b3Transform = @import("std").mem.zeroes(b3Transform),
    /// Should the proxy radius be considered?
    useRadii: bool = false,
    /// Compute the closest points between two shapes represented as point clouds.
    /// b3SimplexCache cache is input/output. On the first call set b3SimplexCache.count to zero.
    /// The query runs in frame A, so the witness points and normal are returned in frame A.
    /// The underlying GJK algorithm may be debugged by passing in debug simplexes and capacity. You may pass in NULL and 0 for these.
    pub const b3ShapeDistance = __root.b3ShapeDistance;
};
/// Input for b3ShapeDistance
pub const b3DistanceInput = struct_b3DistanceInput;
pub const struct_b3DistanceOutput = extern struct {
    /// Closest point on shapeA, in shape A's frame
    pointA: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Closest point on shapeB, in shape A's frame
    pointB: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// A to B normal in shape A's frame. Invalid if distance is zero.
    normal: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The final distance, zero if overlapped
    distance: f32 = 0,
    /// Number of GJK iterations used
    iterations: c_int = 0,
    /// The number of simplexes stored in the simplex array
    simplexCount: c_int = 0,
};
/// Output for b3ShapeDistance
pub const b3DistanceOutput = struct_b3DistanceOutput;
pub const struct_b3SimplexVertex = extern struct {
    /// support point in proxyA
    wA: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// support point in proxyB
    wB: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// wB - wA
    w: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// barycentric coordinates
    a: f32 = 0,
    /// wA index
    indexA: c_int = 0,
    /// wB index
    indexB: c_int = 0,
};
/// Simplex vertex for debugging the GJK algorithm
pub const b3SimplexVertex = struct_b3SimplexVertex;
pub const struct_b3Simplex = extern struct {
    /// vertices
    vertices: [4]b3SimplexVertex = @import("std").mem.zeroes([4]b3SimplexVertex),
    /// number of valid vertices
    count: c_int = 0,
};
/// Simplex from the GJK algorithm
pub const b3Simplex = struct_b3Simplex;
pub const struct_b3Sweep = extern struct {
    /// Local center of mass position
    localCenter: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Starting center of mass world position
    c1: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Ending center of mass world position
    c2: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Starting world rotation
    q1: b3Quat = @import("std").mem.zeroes(b3Quat),
    /// Ending world rotation
    q2: b3Quat = @import("std").mem.zeroes(b3Quat),
    /// Evaluate the transform sweep at a specific time.
    pub const b3GetSweepTransform = __root.b3GetSweepTransform;
};
/// This describes the motion of a body/shape for TOI computation. Shapes are defined with respect to the body origin,
/// which may not coincide with the center of mass. However, to support dynamics we must interpolate the center of mass
/// position.
pub const b3Sweep = struct_b3Sweep;
pub const struct_b3TOIInput = extern struct {
    /// The proxy for shape A
    proxyA: b3ShapeProxy = @import("std").mem.zeroes(b3ShapeProxy),
    /// The proxy for shape B
    proxyB: b3ShapeProxy = @import("std").mem.zeroes(b3ShapeProxy),
    /// The movement of shape A
    sweepA: b3Sweep = @import("std").mem.zeroes(b3Sweep),
    /// The movement of shape B
    sweepB: b3Sweep = @import("std").mem.zeroes(b3Sweep),
    /// Defines the sweep interval [0, tMax]
    maxFraction: f32 = 0,
    /// Compute the upper bound on time before two shapes penetrate. Time is represented as
    /// a fraction between [0,tMax]. This uses a swept separating axis and may miss some intermediate,
    /// non-tunneling collisions. If you change the time interval, you should call this function
    /// again.
    pub const b3TimeOfImpact = __root.b3TimeOfImpact;
};
/// Time of impact input
pub const b3TOIInput = struct_b3TOIInput;
pub const b3_toiStateUnknown: c_int = 0;
pub const b3_toiStateFailed: c_int = 1;
pub const b3_toiStateOverlapped: c_int = 2;
pub const b3_toiStateHit: c_int = 3;
pub const b3_toiStateSeparated: c_int = 4;
pub const enum_b3TOIState = c_uint;
/// Describes the TOI output
pub const b3TOIState = enum_b3TOIState;
pub const struct_b3TOIOutput = extern struct {
    /// The type of result
    state: b3TOIState = @import("std").mem.zeroes(b3TOIState),
    /// The hit point
    point: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The hit normal
    normal: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The sweep time of the collision
    fraction: f32 = 0,
    /// The final distance
    distance: f32 = 0,
    /// Number of outer iterations
    distanceIterations: c_int = 0,
    /// Total number of push back iterations
    pushBackIterations: c_int = 0,
    /// Total number of root iterations
    rootIterations: c_int = 0,
    /// Indicates that the time of impact detected initial
    /// overlap and used a fallback sphere as a last ditch effort
    /// to prevent tunneling.
    usedFallback: bool = false,
};
/// Time of impact output
pub const b3TOIOutput = struct_b3TOIOutput;
pub const b3_allocatedNode: c_int = 1;
pub const b3_enlargedNode: c_int = 2;
pub const b3_leafNode: c_int = 4;
pub const enum_b3TreeNodeFlags = c_uint;
/// Flags for tree nodes. For internal usage.
pub const b3TreeNodeFlags = enum_b3TreeNodeFlags;
pub const struct_b3TreeStats = extern struct {
    /// Number of internal nodes visited during the query
    nodeVisits: c_int = 0,
    /// Number of leaf nodes visited during the query
    leafVisits: c_int = 0,
};
/// These are performance results returned by dynamic tree queries.
pub const b3TreeStats = struct_b3TreeStats;
/// This function receives proxies found in the AABB query.
/// @return true if the query should continue
pub const b3TreeQueryCallbackFcn = fn (proxyId: c_int, userData: u64, context: ?*anyopaque) callconv(.c) bool;
/// This function receives the minimum distance squared so far and proxy to check in the closest query.
/// @return minimum distance squared to user objects in the proxy
pub const b3TreeQueryClosestCallbackFcn = fn (distanceSqrMin: f32, proxyId: c_int, userData: u64, context: ?*anyopaque) callconv(.c) f32;
/// This function receives clipped AABB cast input for a proxy. The function returns the new cast
/// fraction.
/// - return a value of 0 to terminate the cast
/// - return a value less than input->maxFraction to clip the cast
/// - return a value of input->maxFraction to continue the cast without clipping
pub const b3TreeBoxCastCallbackFcn = fn (input: [*c]const b3BoxCastInput, proxyId: c_int, userData: u64, context: ?*anyopaque) callconv(.c) f32;
/// This function receives clipped ray cast input for a proxy. The function
/// returns the new ray fraction.
/// - return a value of 0 to terminate the ray cast
/// - return a value less than input->maxFraction to clip the ray
/// - return a value of input->maxFraction to continue the ray cast without clipping
pub const b3TreeRayCastCallbackFcn = fn (input: [*c]const b3RayCastInput, proxyId: c_int, userData: u64, context: ?*anyopaque) callconv(.c) f32;
pub const struct_b3PlaneResult = extern struct {
    /// Outward pointing plane.
    plane: b3Plane = @import("std").mem.zeroes(b3Plane),
    /// Closest point on the shape. May not be unique.
    point: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
};
/// The plane between a character mover and a shape
pub const b3PlaneResult = struct_b3PlaneResult;
pub const struct_b3CollisionPlane = extern struct {
    /// The collision plane between the mover and some shape.
    plane: b3Plane = @import("std").mem.zeroes(b3Plane),
    /// Setting this to FLT_MAX makes the plane as rigid as possible. Lower values can
    /// make the plane collision soft. Usually in meters.
    pushLimit: f32 = 0,
    /// The push on the mover determined by b3SolvePlanes. Usually in meters.
    push: f32 = 0,
    /// Indicates if b3ClipVector should clip against this plane. Should be false for soft collision.
    clipVelocity: bool = false,
};
/// These are collision planes that can be fed to b3SolvePlanes. Normally
/// this is assembled by the user from plane results in b3PlaneResult.
pub const b3CollisionPlane = struct_b3CollisionPlane;
pub const struct_b3PlaneSolverResult = extern struct {
    /// The final relative translation.
    delta: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The number of iterations used by the plane solver. For diagnostics.
    iterationCount: c_int = 0,
};
/// Result returned by b3SolvePlanes.
pub const b3PlaneSolverResult = struct_b3PlaneSolverResult;
pub const struct_b3BodyPlaneResult = extern struct {
    /// The shape id on the body.
    shapeId: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    /// The plane result.
    result: b3PlaneResult = @import("std").mem.zeroes(b3PlaneResult),
};
/// Body plane result for movers.
pub const b3BodyPlaneResult = struct_b3BodyPlaneResult;
/// Used to collect collision planes for character movers.
/// Return true to continue gathering planes.
pub const b3PlaneResultFcn = fn (shapeId: b3ShapeId, plane: [*c]const b3PlaneResult, planeCount: c_int, context: ?*anyopaque) callconv(.c) bool;
/// Used to filter shapes for shape casting character movers.
/// Return true to accept the collision
pub const b3MoverFilterFcn = fn (shapeId: b3ShapeId, context: ?*anyopaque) callconv(.c) bool;
pub const struct_b3MassData = extern struct {
    /// The shape mass
    mass: f32 = 0,
    /// The local center of mass position.
    center: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The inertia tensor about the shape center of mass.
    inertia: b3Matrix3 = @import("std").mem.zeroes(b3Matrix3),
};
/// This holds the mass data computed for a shape.
pub const b3MassData = struct_b3MassData;
pub const struct_b3HullVertex = extern struct {
    /// A half-edge that has this vertex as the origin
    /// Can be used along with edge twins and winding order
    /// to traverse all the edges connected to this vertex.
    edge: u8 = 0,
};
/// A hull vertex. Identified by a half-edge with this vertex as its tail.
pub const b3HullVertex = struct_b3HullVertex;
pub const struct_b3HullHalfEdge = extern struct {
    /// Next edge index CCW
    next: u8 = 0,
    /// Twin edge index
    twin: u8 = 0,
    /// index of origin vertex and point
    origin: u8 = 0,
    /// Face to the left of this edge
    face: u8 = 0,
};
/// Half-edge for hull data structure
pub const b3HullHalfEdge = struct_b3HullHalfEdge;
pub const struct_b3HullFace = extern struct {
    /// An arbitrary half-edge on this face
    edge: u8 = 0,
};
/// A hull face. Hulls use a half-edge data structure, so a face
/// can be determined from a single half-edge index.
pub const b3HullFace = struct_b3HullFace;
pub const struct_b3BoxHull = extern struct {
    /// The embedded hull. So the offsets index into the arrays that follow.
    base: b3HullData = @import("std").mem.zeroes(b3HullData),
    /// Box vertices.
    boxVertices: [8]b3HullVertex = @import("std").mem.zeroes([8]b3HullVertex),
    /// Box points.
    boxPoints: [8]b3Vec3 = @import("std").mem.zeroes([8]b3Vec3),
    /// Box half-edges.
    boxEdges: [24]b3HullHalfEdge = @import("std").mem.zeroes([24]b3HullHalfEdge),
    /// Box face planes.
    boxPlanes: [6]b3Plane = @import("std").mem.zeroes([6]b3Plane),
    /// Box faces.
    boxFaces: [6]b3HullFace = @import("std").mem.zeroes([6]b3HullFace),
    /// Explicit padding, see b3HullData::padding.
    padding: [10]u8 = @import("std").mem.zeroes([10]u8),
    /// vertex x
    vx: [8]f32 = @import("std").mem.zeroes([8]f32),
    /// vertex y
    vy: [8]f32 = @import("std").mem.zeroes([8]f32),
    /// vertex z
    vz: [8]f32 = @import("std").mem.zeroes([8]f32),
    /// normal x, padded to multiple of 4
    nx: [8]f32 = @import("std").mem.zeroes([8]f32),
    /// normal y, padded to multiple of 4
    ny: [8]f32 = @import("std").mem.zeroes([8]f32),
    /// normal z, padded to multiple of 4
    nz: [8]f32 = @import("std").mem.zeroes([8]f32),
};
/// Efficient box hull
pub const b3BoxHull = struct_b3BoxHull;
pub const struct_b3MeshDef = extern struct {
    /// Triangle vertices
    vertices: [*c]b3Vec3 = null,
    /// Triangle vertex indices. 3 for each triangle. CCW winding.
    indices: [*c]i32 = null,
    /// Triangle material index. 1 per triangle. Indexes into b3ShapeDef::materials.
    /// This allows different run-time material data to be associated with different
    /// instances of this mesh.
    materialIndices: [*c]u8 = null,
    /// Tolerance for vertex welding in length units.
    weldTolerance: f32 = 0,
    /// The vertex count. Must be 3 or more.
    vertexCount: c_int = 0,
    /// The triangle count. Must be 1 or more.
    triangleCount: c_int = 0,
    /// Optionally weld nearby vertices.
    weldVertices: bool = false,
    /// Use the median split instead of SAH to speed up mesh creation. Good
    /// for meshes that are structured like a grid.
    useMedianSplit: bool = false,
    /// Compute triangle adjacency information using shared edges
    identifyEdges: bool = false,
    /// Create a generic mesh.
    pub const b3CreateMesh = __root.b3CreateMesh;
};
/// This is used to create a re-usable collision mesh.
pub const b3MeshDef = struct_b3MeshDef;
pub const b3_concaveEdge1: c_int = 1;
pub const b3_concaveEdge2: c_int = 2;
pub const b3_concaveEdge3: c_int = 4;
pub const b3_inverseConcaveEdge1: c_int = 16;
pub const b3_inverseConcaveEdge2: c_int = 32;
pub const b3_inverseConcaveEdge3: c_int = 64;
pub const b3_allConcaveEdges: c_int = 7;
pub const b3_flatEdge1: c_int = 17;
pub const b3_flatEdge2: c_int = 34;
pub const b3_flatEdge3: c_int = 68;
pub const b3_allFlatEdges: c_int = 119;
pub const enum_b3MeshEdgeFlags = c_uint;
/// Triangle mesh edge flags.
pub const b3MeshEdgeFlags = enum_b3MeshEdgeFlags;
pub const struct_b3MeshTriangle = extern struct {
    /// Index of vertex 1.
    index1: i32 = 0,
    /// Index of vertex 2.
    index2: i32 = 0,
    /// Index of vertex 3.
    index3: i32 = 0,
};
/// A mesh triangle.
pub const b3MeshTriangle = struct_b3MeshTriangle; // box3d/include/box3d/types.h:2145:13: warning: struct demoted to opaque type - has bitfield
const struct_unnamed_6 = opaque {}; // box3d/include/box3d/types.h:2148:5: warning: union demoted to opaque type - has opaque field
const union_unnamed_5 = opaque {}; // box3d/include/box3d/types.h:2159:4: warning: struct demoted to opaque type - has opaque field
pub const struct_b3MeshNode = opaque {};
/// A mesh BVH node.
pub const b3MeshNode = struct_b3MeshNode;
pub const struct_b3HeightFieldDef = extern struct {
    /// Grid point heights
    /// count = countX * countZ
    heights: [*c]f32 = null,
    /// Grid cell material
    /// A value of 0xFF is reserved for holes
    /// count = (countX - 1) * (countZ - 1)
    materialIndices: [*c]u8 = null,
    /// The height field scale. All components must be positive values.
    scale: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The number of grid lines along the x-axis.
    countX: c_int = 0,
    /// The number of grid lines along the z-axis.
    countZ: c_int = 0,
    /// Global minimum and maximum heights used for quantization. This is important
    /// if you want height fields to be placed next to each other and line up exactly.
    /// In that case, both height fields should use the same minimum and maximum heights.
    /// All height values are clamped to this range.
    /// These values are in unscaled space.
    globalMinimumHeight: f32 = 0,
    /// The maximum.
    globalMaximumHeight: f32 = 0,
    /// Use clock-wise winding. This effectively inverts the height-field along the y-axis.
    clockwiseWinding: bool = false,
    /// Create a generic height field.
    pub const b3CreateHeightField = __root.b3CreateHeightField;
    /// Save input height data to a file
    pub const b3DumpHeightData = __root.b3DumpHeightData;
};
/// Data used to create a height field
pub const b3HeightFieldDef = struct_b3HeightFieldDef;
pub const struct_b3CompoundCapsuleDef = extern struct {
    /// Local capsule.
    capsule: b3Capsule = @import("std").mem.zeroes(b3Capsule),
    /// Material properties.
    material: b3SurfaceMaterial = @import("std").mem.zeroes(b3SurfaceMaterial),
};
/// Definition for a capsule in a compound shape.
pub const b3CompoundCapsuleDef = struct_b3CompoundCapsuleDef;
pub const struct_b3CompoundHullDef = extern struct {
    /// Shared hull.
    hull: [*c]const b3HullData = null,
    /// Transform of the shared hull into compound local space.
    transform: b3Transform = @import("std").mem.zeroes(b3Transform),
    /// Material properties.
    material: b3SurfaceMaterial = @import("std").mem.zeroes(b3SurfaceMaterial),
};
/// Definition for a convex hull in a compound shape.
pub const b3CompoundHullDef = struct_b3CompoundHullDef;
pub const struct_b3CompoundMeshDef = extern struct {
    /// Shared mesh.
    meshData: [*c]const b3MeshData = null,
    /// Transform of the shared mesh into compound local space.
    transform: b3Transform = @import("std").mem.zeroes(b3Transform),
    /// Local space non-uniform mesh scale. May have negative components.
    scale: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// Material properties.
    /// This array must line up with the material indices on the triangles.
    materials: [*c]const b3SurfaceMaterial = null,
    /// Number of materials.
    materialCount: c_int = 0,
};
/// Definition for a triangle mesh in a compound shape.
pub const b3CompoundMeshDef = struct_b3CompoundMeshDef;
pub const struct_b3CompoundSphereDef = extern struct {
    /// Local sphere.
    sphere: b3Sphere = @import("std").mem.zeroes(b3Sphere),
    /// Material properties.
    material: b3SurfaceMaterial = @import("std").mem.zeroes(b3SurfaceMaterial),
};
/// Definition for a sphere in a compound shape.
pub const b3CompoundSphereDef = struct_b3CompoundSphereDef;
pub const struct_b3CompoundDef = extern struct {
    /// Capsule instances.
    capsules: [*c]b3CompoundCapsuleDef = null,
    /// Number of capsules.
    capsuleCount: c_int = 0,
    /// Hulls instances.
    hulls: [*c]b3CompoundHullDef = null,
    /// Number of hull instances.
    hullCount: c_int = 0,
    /// Mesh instances.
    meshes: [*c]b3CompoundMeshDef = null,
    /// Number of mesh instances.
    meshCount: c_int = 0,
    /// Sphere instances.
    spheres: [*c]b3CompoundSphereDef = null,
    /// Number of spheres.
    sphereCount: c_int = 0,
    /// Create a compound shape. All input data in the definition is cloned into the resulting compound.
    pub const b3CreateCompound = __root.b3CreateCompound;
};
/// Definition for creating a compound shape. All this data is fully cloned
/// into the run-time compound shape.
pub const b3CompoundDef = struct_b3CompoundDef;
pub const struct_b3CompoundCapsule = extern struct {
    /// Local capsule.
    capsule: b3Capsule = @import("std").mem.zeroes(b3Capsule),
    /// Index to a shared material.
    materialIndex: c_int = 0,
};
/// A capsule that lives in a compound.
pub const b3CompoundCapsule = struct_b3CompoundCapsule;
pub const struct_b3CompoundHull = extern struct {
    /// Pointer to the unique shared hull.
    hull: [*c]const b3HullData = null,
    /// The transform of this hull instance.
    transform: b3Transform = @import("std").mem.zeroes(b3Transform),
    /// Index to a shared material.
    materialIndex: c_int = 0,
};
/// A hull that lives in a compound.
pub const b3CompoundHull = struct_b3CompoundHull;
pub const struct_b3CompoundMesh = extern struct {
    /// Pointer to the unique shared mesh.
    meshData: [*c]const b3MeshData = null,
    /// The transform of this mesh instance.
    transform: b3Transform = @import("std").mem.zeroes(b3Transform),
    /// Non-uniform scale of this mesh instance.
    scale: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// This is used to access the surface material from b3GetCompoundMaterials.
    /// Requires an extra level of indirection. The triangle material index
    /// is clamped to B3_MAX_COMPOUND_MESH_MATERIALS.
    /// materialIndex = materialIndices[triangle->materialIndex]
    materialIndices: [4]c_int = @import("std").mem.zeroes([4]c_int),
};
/// A mesh with non-uniform scale that lives in a compound.
pub const b3CompoundMesh = struct_b3CompoundMesh;
pub const struct_b3CompoundSphere = extern struct {
    /// Local sphere.
    sphere: b3Sphere = @import("std").mem.zeroes(b3Sphere),
    /// Index to a shared material.
    materialIndex: c_int = 0,
};
/// A sphere that lives in a compound.
pub const b3CompoundSphere = struct_b3CompoundSphere;
const union_unnamed_7 = extern union {
    capsule: b3Capsule,
    hull: [*c]const b3HullData,
    mesh: b3Mesh,
    sphere: b3Sphere,
};
pub const struct_b3ChildShape = extern struct {
    unnamed_0: union_unnamed_7 = @import("std").mem.zeroes(union_unnamed_7),
    /// Tagged union.
    /// Transform of the shape into compound local space.
    transform: b3Transform = @import("std").mem.zeroes(b3Transform),
    /// Material indices. Index 0 is used for convex shapes.
    /// todo limit to 64K?
    materialIndices: [4]c_int = @import("std").mem.zeroes([4]c_int),
    /// The shape type (union tag).
    type: b3ShapeType = @import("std").mem.zeroes(b3ShapeType),
};
/// Child shape of a compound
pub const b3ChildShape = struct_b3ChildShape;
/// Callback for compound overlap queries.
pub const b3CompoundQueryFcn = fn (compound: [*c]const b3CompoundData, childIndex: c_int, context: ?*anyopaque) callconv(.c) bool;
/// A contact manifold describes the contact points between colliding shapes.
/// @note Box3D uses speculative collision so some contact points may be separated.
pub const b3Manifold = struct_b3Manifold;
pub const b3_invalidAxis: c_int = 0;
pub const b3_backsideAxis: c_int = 1;
pub const b3_faceAxisA: c_int = 2;
pub const b3_faceAxisB: c_int = 3;
pub const b3_edgePairAxis: c_int = 4;
pub const b3_closestPointsAxis: c_int = 5;
pub const b3_manualFaceAxisA: c_int = 6;
pub const b3_manualFaceAxisB: c_int = 7;
pub const b3_manualEdgePairAxis: c_int = 8;
pub const b3SeparatingFeature = c_uint;
pub const b3_featureNone: c_int = 0;
pub const b3_featureTriangleFace: c_int = 1;
pub const b3_featureHullFace: c_int = 2;
pub const b3_featureEdge1: c_int = 3;
pub const b3_featureEdge2: c_int = 4;
pub const b3_featureEdge3: c_int = 5;
pub const b3_featureVertex1: c_int = 6;
pub const b3_featureVertex2: c_int = 7;
pub const b3_featureVertex3: c_int = 8;
pub const b3TriangleFeature = c_uint;
pub const b3SATCache = extern struct {
    separation: f32 = 0,
    type: u8 = 0,
    indexA: u8 = 0,
    indexB: u8 = 0,
    hit: u8 = 0,
};
pub const struct_b3FeaturePair = extern struct {
    /// Incoming type (either edge on shape A or shape B)
    owner1: u8 = 0,
    /// Incoming edge index (into associated shape array)
    index1: u8 = 0,
    /// Outgoing type (either edge on shape A or shape B)
    owner2: u8 = 0,
    /// Outgoing edge index (into associated shape array)
    index2: u8 = 0,
};
/// Contact points are always the result of two edges intersecting.
/// It can be two edges of the same shape, which is just a shape vertex.
/// Or a contact point can be the result of two edges crossing from different shapes.
/// This is designed to support hull versus hull, but it is adapted to work
/// with all shape types. The feature pair is used to identify contact points
/// for temporal coherence and warm starting.
pub const b3FeaturePair = struct_b3FeaturePair;
pub const struct_b3LocalManifoldPoint = extern struct {
    /// Local point in frame A.
    point: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The contact point separation. Negative for overlap.
    separation: f32 = 0,
    /// The feature pair for this point.
    pair: b3FeaturePair = @import("std").mem.zeroes(b3FeaturePair),
    /// The triangle index when collide with a mesh or height-field.
    triangleIndex: c_int = 0,
};
/// A local manifold point and normal in frame A.
pub const b3LocalManifoldPoint = struct_b3LocalManifoldPoint;
pub const struct_b3LocalManifold = extern struct {
    /// Local normal in frame A.
    normal: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The triangle normal.
    triangleNormal: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    /// The manifold points. From a point buffer.
    points: [*c]b3LocalManifoldPoint = null,
    /// The number of manifold points. Only bounded by the buffer capacity.
    pointCount: c_int = 0,
    /// The index of the triangle.
    triangleIndex: c_int = 0,
    /// Vertex 1 index.
    i1: c_int = 0,
    /// Vertex 2 index.
    i2: c_int = 0,
    /// Vertex 3 index.
    i3: c_int = 0,
    /// The squared distance of a sphere from a triangle. For ghost collision reduction.
    squaredDistance: f32 = 0,
    /// The triangle feature involved.
    feature: b3TriangleFeature = @import("std").mem.zeroes(b3TriangleFeature),
    /// b3MeshEdgeFlags.
    triangleFlags: c_int = 0,
    /// Collide two spheres.
    pub const b3CollideSpheres = __root.b3CollideSpheres;
    /// Collide a capsule and a sphere.
    pub const b3CollideCapsuleAndSphere = __root.b3CollideCapsuleAndSphere;
    /// Collide a hull and a sphere.
    pub const b3CollideHullAndSphere = __root.b3CollideHullAndSphere;
    /// Collide two capsules.
    pub const b3CollideCapsules = __root.b3CollideCapsules;
    /// Collide a hull and a capsule.
    pub const b3CollideHullAndCapsule = __root.b3CollideHullAndCapsule;
    /// Collide two hulls.
    pub const b3CollideHulls = __root.b3CollideHulls;
    /// Collide a triangle and capsule. Normal points from triangle to capsule.
    pub const b3CollideTriangleAndCapsule = __root.b3CollideTriangleAndCapsule;
    /// Collide a triangle and hull. Normal points from triangle to hull.
    pub const b3CollideTriangleAndHull = __root.b3CollideTriangleAndHull;
    /// Collide a triangle and sphere. Normal points from triangle to sphere.
    pub const b3CollideTriangleAndSphere = __root.b3CollideTriangleAndSphere;
};
/// A local manifold with no dynamic information. Used by b3Collide functions.
pub const b3LocalManifold = struct_b3LocalManifold;
pub const b3_colorAliceBlue: c_int = 15792383;
pub const b3_colorAntiqueWhite: c_int = 16444375;
pub const b3_colorAqua: c_int = 65535;
pub const b3_colorAquamarine: c_int = 8388564;
pub const b3_colorAzure: c_int = 15794175;
pub const b3_colorBeige: c_int = 16119260;
pub const b3_colorBisque: c_int = 16770244;
pub const b3_colorBlack: c_int = 0;
pub const b3_colorBlanchedAlmond: c_int = 16772045;
pub const b3_colorBlue: c_int = 255;
pub const b3_colorBlueViolet: c_int = 9055202;
pub const b3_colorBrown: c_int = 10824234;
pub const b3_colorBurlywood: c_int = 14596231;
pub const b3_colorCadetBlue: c_int = 6266528;
pub const b3_colorChartreuse: c_int = 8388352;
pub const b3_colorChocolate: c_int = 13789470;
pub const b3_colorCoral: c_int = 16744272;
pub const b3_colorCornflowerBlue: c_int = 6591981;
pub const b3_colorCornsilk: c_int = 16775388;
pub const b3_colorCrimson: c_int = 14423100;
pub const b3_colorCyan: c_int = 65535;
pub const b3_colorDarkBlue: c_int = 139;
pub const b3_colorDarkCyan: c_int = 35723;
pub const b3_colorDarkGoldenRod: c_int = 12092939;
pub const b3_colorDarkGray: c_int = 11119017;
pub const b3_colorDarkGreen: c_int = 25600;
pub const b3_colorDarkKhaki: c_int = 12433259;
pub const b3_colorDarkMagenta: c_int = 9109643;
pub const b3_colorDarkOliveGreen: c_int = 5597999;
pub const b3_colorDarkOrange: c_int = 16747520;
pub const b3_colorDarkOrchid: c_int = 10040012;
pub const b3_colorDarkRed: c_int = 9109504;
pub const b3_colorDarkSalmon: c_int = 15308410;
pub const b3_colorDarkSeaGreen: c_int = 9419919;
pub const b3_colorDarkSlateBlue: c_int = 4734347;
pub const b3_colorDarkSlateGray: c_int = 3100495;
pub const b3_colorDarkTurquoise: c_int = 52945;
pub const b3_colorDarkViolet: c_int = 9699539;
pub const b3_colorDeepPink: c_int = 16716947;
pub const b3_colorDeepSkyBlue: c_int = 49151;
pub const b3_colorDimGray: c_int = 6908265;
pub const b3_colorDodgerBlue: c_int = 2003199;
pub const b3_colorFireBrick: c_int = 11674146;
pub const b3_colorFloralWhite: c_int = 16775920;
pub const b3_colorForestGreen: c_int = 2263842;
pub const b3_colorFuchsia: c_int = 16711935;
pub const b3_colorGainsboro: c_int = 14474460;
pub const b3_colorGhostWhite: c_int = 16316671;
pub const b3_colorGold: c_int = 16766720;
pub const b3_colorGoldenRod: c_int = 14329120;
pub const b3_colorGray: c_int = 8421504;
pub const b3_colorGreen: c_int = 32768;
pub const b3_colorGreenYellow: c_int = 11403055;
pub const b3_colorHoneyDew: c_int = 15794160;
pub const b3_colorHotPink: c_int = 16738740;
pub const b3_colorIndianRed: c_int = 13458524;
pub const b3_colorIndigo: c_int = 4915330;
pub const b3_colorIvory: c_int = 16777200;
pub const b3_colorKhaki: c_int = 15787660;
pub const b3_colorLavender: c_int = 15132410;
pub const b3_colorLavenderBlush: c_int = 16773365;
pub const b3_colorLawnGreen: c_int = 8190976;
pub const b3_colorLemonChiffon: c_int = 16775885;
pub const b3_colorLightBlue: c_int = 11393254;
pub const b3_colorLightCoral: c_int = 15761536;
pub const b3_colorLightCyan: c_int = 14745599;
pub const b3_colorLightGoldenRodYellow: c_int = 16448210;
pub const b3_colorLightGray: c_int = 13882323;
pub const b3_colorLightGreen: c_int = 9498256;
pub const b3_colorLightPink: c_int = 16758465;
pub const b3_colorLightSalmon: c_int = 16752762;
pub const b3_colorLightSeaGreen: c_int = 2142890;
pub const b3_colorLightSkyBlue: c_int = 8900346;
pub const b3_colorLightSlateGray: c_int = 7833753;
pub const b3_colorLightSteelBlue: c_int = 11584734;
pub const b3_colorLightYellow: c_int = 16777184;
pub const b3_colorLime: c_int = 65280;
pub const b3_colorLimeGreen: c_int = 3329330;
pub const b3_colorLinen: c_int = 16445670;
pub const b3_colorMagenta: c_int = 16711935;
pub const b3_colorMaroon: c_int = 8388608;
pub const b3_colorMediumAquaMarine: c_int = 6737322;
pub const b3_colorMediumBlue: c_int = 205;
pub const b3_colorMediumOrchid: c_int = 12211667;
pub const b3_colorMediumPurple: c_int = 9662683;
pub const b3_colorMediumSeaGreen: c_int = 3978097;
pub const b3_colorMediumSlateBlue: c_int = 8087790;
pub const b3_colorMediumSpringGreen: c_int = 64154;
pub const b3_colorMediumTurquoise: c_int = 4772300;
pub const b3_colorMediumVioletRed: c_int = 13047173;
pub const b3_colorMidnightBlue: c_int = 1644912;
pub const b3_colorMintCream: c_int = 16121850;
pub const b3_colorMistyRose: c_int = 16770273;
pub const b3_colorMoccasin: c_int = 16770229;
pub const b3_colorNavajoWhite: c_int = 16768685;
pub const b3_colorNavy: c_int = 128;
pub const b3_colorOldLace: c_int = 16643558;
pub const b3_colorOlive: c_int = 8421376;
pub const b3_colorOliveDrab: c_int = 7048739;
pub const b3_colorOrange: c_int = 16753920;
pub const b3_colorOrangeRed: c_int = 16729344;
pub const b3_colorOrchid: c_int = 14315734;
pub const b3_colorPaleGoldenRod: c_int = 15657130;
pub const b3_colorPaleGreen: c_int = 10025880;
pub const b3_colorPaleTurquoise: c_int = 11529966;
pub const b3_colorPaleVioletRed: c_int = 14381203;
pub const b3_colorPapayaWhip: c_int = 16773077;
pub const b3_colorPeachPuff: c_int = 16767673;
pub const b3_colorPeru: c_int = 13468991;
pub const b3_colorPink: c_int = 16761035;
pub const b3_colorPlum: c_int = 14524637;
pub const b3_colorPowderBlue: c_int = 11591910;
pub const b3_colorPurple: c_int = 8388736;
pub const b3_colorRebeccaPurple: c_int = 6697881;
pub const b3_colorRed: c_int = 16711680;
pub const b3_colorRosyBrown: c_int = 12357519;
pub const b3_colorRoyalBlue: c_int = 4286945;
pub const b3_colorSaddleBrown: c_int = 9127187;
pub const b3_colorSalmon: c_int = 16416882;
pub const b3_colorSandyBrown: c_int = 16032864;
pub const b3_colorSeaGreen: c_int = 3050327;
pub const b3_colorSeaShell: c_int = 16774638;
pub const b3_colorSienna: c_int = 10506797;
pub const b3_colorSilver: c_int = 12632256;
pub const b3_colorSkyBlue: c_int = 8900331;
pub const b3_colorSlateBlue: c_int = 6970061;
pub const b3_colorSlateGray: c_int = 7372944;
pub const b3_colorSnow: c_int = 16775930;
pub const b3_colorSpringGreen: c_int = 65407;
pub const b3_colorSteelBlue: c_int = 4620980;
pub const b3_colorTan: c_int = 13808780;
pub const b3_colorTeal: c_int = 32896;
pub const b3_colorThistle: c_int = 14204888;
pub const b3_colorTomato: c_int = 16737095;
pub const b3_colorTurquoise: c_int = 4251856;
pub const b3_colorViolet: c_int = 15631086;
pub const b3_colorWheat: c_int = 16113331;
pub const b3_colorWhite: c_int = 16777215;
pub const b3_colorWhiteSmoke: c_int = 16119285;
pub const b3_colorYellow: c_int = 16776960;
pub const b3_colorYellowGreen: c_int = 10145074;
pub const b3_colorBox2DRed: c_int = 14430514;
pub const b3_colorBox2DBlue: c_int = 3190463;
pub const b3_colorBox2DGreen: c_int = 9226532;
pub const b3_colorBox2DYellow: c_int = 16772748;
pub const enum_b3HexColor = c_uint;
/// These colors are used for debug draw and mostly match the named SVG colors.
/// See https://www.rapidtables.com/web/color/index.html
/// https://johndecember.com/html/spec/colorsvg.html
/// https://upload.wikimedia.org/wikipedia/commons/2/2b/SVG_Recognized_color_keyword_names.svg
pub const b3HexColor = enum_b3HexColor;
pub const b3_debugMaterialDefault: c_int = 0;
pub const b3_debugMaterialMatte: c_int = 1;
pub const b3_debugMaterialSoft: c_int = 2;
pub const b3_debugMaterialDead: c_int = 3;
pub const b3_debugMaterialGlossy: c_int = 4;
pub const b3_debugMaterialMetallic: c_int = 5;
pub const enum_b3DebugMaterial = c_uint;
/// Debug draw material preset. Optionally packed into the unused high byte of a
/// b3HexColor (or b3SurfaceMaterial::customColor) to drive the renderer's PBR
/// roughness and metalness. The low 24 bits stay RGB, so a plain 0xRRGGBB color
/// reads as b3_debugMaterialDefault and keeps the renderer's per-body-type look.
pub const b3DebugMaterial = enum_b3DebugMaterial;
/// Pack an RGB color with a material preset for debug draw. The preset rides in
/// the high byte where the color converters ignore it.
pub fn b3MakeDebugColor(arg_rgb: b3HexColor, arg_material: b3DebugMaterial) callconv(.c) u32 {
    var rgb = arg_rgb;
    _ = &rgb;
    var material = arg_material;
    _ = &material;
    return (rgb & @as(c_uint, 16777215)) | (material << @intCast(@as(u32, 24)));
}
/// Get the visualization color assigned to a constraint graph color slot. The last index
/// (B3_GRAPH_COLOR_COUNT - 1) is the overflow color.
pub extern fn b3GetGraphColor(index: c_int) b3HexColor;
pub const struct_b3DebugDraw = extern struct {
    DrawShapeFcn: ?*const fn (userShape: ?*anyopaque, transform: b3WorldTransform, color: b3HexColor, context: ?*anyopaque) callconv(.c) void = null,
    DrawSegmentFcn: ?*const fn (p1: b3Pos, p2: b3Pos, color: b3HexColor, context: ?*anyopaque) callconv(.c) void = null,
    DrawTransformFcn: ?*const fn (transform: b3WorldTransform, context: ?*anyopaque) callconv(.c) void = null,
    DrawPointFcn: ?*const fn (p: b3Pos, size: f32, color: b3HexColor, context: ?*anyopaque) callconv(.c) void = null,
    DrawSphereFcn: ?*const fn (p: b3Pos, radius: f32, color: b3HexColor, alpha: f32, context: ?*anyopaque) callconv(.c) void = null,
    DrawCapsuleFcn: ?*const fn (p1: b3Pos, p2: b3Pos, radius: f32, color: b3HexColor, alpha: f32, context: ?*anyopaque) callconv(.c) void = null,
    DrawBoundsFcn: ?*const fn (aabb: b3AABB, color: b3HexColor, context: ?*anyopaque) callconv(.c) void = null,
    DrawBoxFcn: ?*const fn (extents: b3Vec3, transform: b3WorldTransform, color: b3HexColor, context: ?*anyopaque) callconv(.c) void = null,
    DrawStringFcn: ?*const fn (p: b3Pos, s: [*c]const u8, color: b3HexColor, context: ?*anyopaque) callconv(.c) void = null,
    /// World bounds to use for debug draw
    drawingBounds: b3AABB = @import("std").mem.zeroes(b3AABB),
    /// Scale to use when drawing forces
    forceScale: f32 = 0,
    /// Global scaling for joint drawing
    jointScale: f32 = 0,
    /// Option to draw shapes
    drawShapes: bool = false,
    /// Option to draw joints
    drawJoints: bool = false,
    /// Option to draw additional information for joints
    drawJointExtras: bool = false,
    /// Option to draw the bounding boxes for shapes
    drawBounds: bool = false,
    /// Option to draw the mass and center of mass of dynamic bodies
    drawMass: bool = false,
    /// Option to draw the sleep information for dynamic and kinematic bodies
    drawSleep: bool = false,
    /// Option to draw body names
    drawBodyNames: bool = false,
    /// Option to draw contact points
    drawContacts: bool = false,
    /// Draw contact anchor A or B
    drawAnchorA: bool = false,
    /// Option to visualize the graph coloring used for contacts and joints
    drawGraphColors: bool = false,
    /// Option to draw contact features
    drawContactFeatures: bool = false,
    /// Option to draw contact normals
    drawContactNormals: bool = false,
    /// Option to draw contact normal forces
    drawContactForces: bool = false,
    /// Option to draw islands as bounding boxes
    drawIslands: bool = false,
    /// User context that is passed as an argument to drawing callback functions
    context: ?*anyopaque = null,
};
/// This struct is passed to b3World_Draw to draw a debug view of the simulation world.
/// Callbacks receive world coordinates. In large world mode the translation is double precision so
/// it stays accurate far from the origin. Shift into your own camera frame inside the callbacks.
pub const b3DebugDraw = struct_b3DebugDraw;
/// Create a debug draw struct with default values.
pub extern fn b3DefaultDebugDraw() b3DebugDraw;
pub const ptrdiff_t = c_long;
pub const wchar_t = c_int;
pub const max_align_t = extern struct {
    __aro_max_align_ll: c_longlong = 0,
    __aro_max_align_ld: c_longdouble = 0,
};
/// Constructing the tree initializes the node pool.
pub extern fn b3DynamicTree_Create(proxyCapacity: c_int) b3DynamicTree;
/// Destroy the tree, freeing the node pool.
pub extern fn b3DynamicTree_Destroy(tree: [*c]b3DynamicTree) void;
/// Create a proxy. Provide an AABB and a userData value.
pub extern fn b3DynamicTree_CreateProxy(tree: [*c]b3DynamicTree, aabb: b3AABB, categoryBits: u64, userData: u64) c_int;
/// Destroy a proxy. This asserts if the id is invalid.
pub extern fn b3DynamicTree_DestroyProxy(tree: [*c]b3DynamicTree, proxyId: c_int) void;
/// Move a proxy to a new AABB by removing and reinserting into the tree.
pub extern fn b3DynamicTree_MoveProxy(tree: [*c]b3DynamicTree, proxyId: c_int, aabb: b3AABB) void;
/// Enlarge a proxy and enlarge ancestors as necessary.
pub extern fn b3DynamicTree_EnlargeProxy(tree: [*c]b3DynamicTree, proxyId: c_int, aabb: b3AABB) void;
/// Modify the category bits on a proxy. This is an expensive operation.
pub extern fn b3DynamicTree_SetCategoryBits(tree: [*c]b3DynamicTree, proxyId: c_int, categoryBits: u64) void;
/// Get the category bits on a proxy.
pub extern fn b3DynamicTree_GetCategoryBits(tree: [*c]b3DynamicTree, proxyId: c_int) u64;
/// Query an AABB for overlapping proxies. The callback function is called for each proxy that overlaps the supplied AABB.
/// @return performance data
pub extern fn b3DynamicTree_Query(tree: [*c]const b3DynamicTree, aabb: b3AABB, maskBits: u64, requireAllBits: bool, callback: ?*const b3TreeQueryCallbackFcn, context: ?*anyopaque) b3TreeStats;
/// Query an AABB for the closest object. The callback function is called for each proxy that might be closest to the supplied
/// point.
/// @param tree the dynamic tree to query
/// @param point the query point
/// @param maskBits nodes are skipped if the bit-wise AND with the node category bits is zero
/// @param requireAllBits nodes are skipped if the bit-wise AND with the node category bits does not equal the maskBits
/// @param callback a user provided instance of b3TreeQueryClosestCallbackFcn
/// @param context a user context object that is provided to the callback
/// @param minDistanceSqr the initial and final minimum squared distance. Provide a small initial to restrict the search and
/// improve performance. If the value is large this query has performance that scales linearly with the number of proxies and
/// would be slower than a brute force search.
/// @return performance data
pub extern fn b3DynamicTree_QueryClosest(tree: [*c]const b3DynamicTree, point: b3Vec3, maskBits: u64, requireAllBits: bool, callback: ?*const b3TreeQueryClosestCallbackFcn, context: ?*anyopaque, minDistanceSqr: [*c]f32) b3TreeStats;
/// Ray cast against the proxies in the tree. This relies on the callback
/// to perform an exact ray cast in the case where the proxy contains a shape.
/// The callback also performs any collision filtering. This has performance
/// roughly equal to k * log(n), where k is the number of collisions and n is the
/// number of proxies in the tree.
/// Bit-wise filtering using mask bits can greatly improve performance in some scenarios.
/// However, this filtering may be approximate, so the user should still apply filtering to results.
/// @param tree the dynamic tree to ray cast
/// @param input the ray cast input data. The ray extends from p1 to p1 + maxFraction * (p2 - p1)
/// @param maskBits bit mask test: `bool accept = (maskBits & node->categoryBits) != 0;`
/// @param requireAllBits modifies bit mask test: `bool accept = (maskBits & node->categoryBits) == maskBits;`
/// @param callback a callback function that is called for each proxy that is hit by the ray
/// @param context user context that is passed to the callback
/// @return performance data
pub extern fn b3DynamicTree_RayCast(tree: [*c]const b3DynamicTree, input: [*c]const b3RayCastInput, maskBits: u64, requireAllBits: bool, callback: ?*const b3TreeRayCastCallbackFcn, context: ?*anyopaque) b3TreeStats;
/// Sweep an AABB through the tree. The box is in the tree's world float frame and the callback
/// re-differences each shape at full precision against the query origin. Used by the large world
/// spatial queries so the tree traversal stays float while the narrow phase stays precise.
pub extern fn b3DynamicTree_BoxCast(tree: [*c]const b3DynamicTree, input: [*c]const b3BoxCastInput, maskBits: u64, requireAllBits: bool, callback: ?*const b3TreeBoxCastCallbackFcn, context: ?*anyopaque) b3TreeStats;
/// Get the height of the binary tree.
pub extern fn b3DynamicTree_GetHeight(tree: [*c]const b3DynamicTree) c_int;
/// Get the ratio of the sum of the node areas to the root area.
pub extern fn b3DynamicTree_GetAreaRatio(tree: [*c]const b3DynamicTree) f32;
/// Get the bounding box that contains the entire tree
pub extern fn b3DynamicTree_GetRootBounds(tree: [*c]const b3DynamicTree) b3AABB;
/// Get the number of proxies created
pub extern fn b3DynamicTree_GetProxyCount(tree: [*c]const b3DynamicTree) c_int;
/// Rebuild the tree while retaining subtrees that haven't changed. Returns the number of boxes sorted.
pub extern fn b3DynamicTree_Rebuild(tree: [*c]b3DynamicTree, fullBuild: bool) c_int;
/// Get the number of bytes used by this tree
pub extern fn b3DynamicTree_GetByteCount(tree: [*c]const b3DynamicTree) c_int;
/// Validate this tree. For testing.
pub extern fn b3DynamicTree_Validate(tree: [*c]const b3DynamicTree) void;
/// Validate this tree has no enlarged AABBs. For testing.
pub extern fn b3DynamicTree_ValidateNoEnlarged(tree: [*c]const b3DynamicTree) void;
/// Save this tree to a file for debugging
pub extern fn b3DynamicTree_Save(tree: [*c]const b3DynamicTree, fileName: [*c]const u8) void;
/// Load a file for debugging
pub extern fn b3DynamicTree_Load(fileName: [*c]const u8, scale: f32) b3DynamicTree;
/// Get proxy user data
pub fn b3DynamicTree_GetUserData(arg_tree: [*c]const b3DynamicTree, arg_proxyId: c_int) callconv(.c) u64 {
    var tree = arg_tree;
    _ = &tree;
    var proxyId = arg_proxyId;
    _ = &proxyId;
    return tree.*.nodes[@bitCast(@as(isize, @intCast(proxyId)))].unnamed_0.userData;
}
/// Get the AABB of a proxy
pub fn b3DynamicTree_GetAABB(arg_tree: [*c]const b3DynamicTree, arg_proxyId: c_int) callconv(.c) b3AABB {
    var tree = arg_tree;
    _ = &tree;
    var proxyId = arg_proxyId;
    _ = &proxyId;
    return tree.*.nodes[@bitCast(@as(isize, @intCast(proxyId)))].aabb;
}
/// Get read only hull vertices.
pub fn b3GetHullVertices(arg_hull: [*c]const b3HullData) callconv(.c) [*c]const b3HullVertex {
    var hull = arg_hull;
    _ = &hull;
    if (hull.*.vertexOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(hull))) + @as(isize, hull.*.vertexOffset))));
}
/// Get read only hull points.
pub fn b3GetHullPoints(arg_hull: [*c]const b3HullData) callconv(.c) [*c]const b3Vec3 {
    var hull = arg_hull;
    _ = &hull;
    if (hull.*.pointOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(hull))) + @as(isize, hull.*.pointOffset))));
}
/// Get read only hull half edges.
pub fn b3GetHullEdges(arg_hull: [*c]const b3HullData) callconv(.c) [*c]const b3HullHalfEdge {
    var hull = arg_hull;
    _ = &hull;
    if (hull.*.edgeOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(hull))) + @as(isize, hull.*.edgeOffset))));
}
/// Get read only hull planes.
pub fn b3GetHullPlanes(arg_hull: [*c]const b3HullData) callconv(.c) [*c]const b3Plane {
    var hull = arg_hull;
    _ = &hull;
    if (hull.*.planeOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(hull))) + @as(isize, hull.*.planeOffset))));
}
/// Get read only hull faces.
pub fn b3GetHullFaces(arg_hull: [*c]const b3HullData) callconv(.c) [*c]const b3HullFace {
    var hull = arg_hull;
    _ = &hull;
    if (hull.*.faceOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(hull))) + @as(isize, hull.*.faceOffset))));
}
/// Get read only SOA vertices. This is an array of vertices with all x values,
/// y values, and z values as separate arrays. The array lengths are padded to
/// a multiple of 4. The padded values are repeats of the first value.
pub fn b3GetHullSoaVertices(arg_hull: [*c]const b3HullData) callconv(.c) [*c]const f32 {
    var hull = arg_hull;
    _ = &hull;
    if (hull.*.soaVertexOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(hull))) + @as(isize, hull.*.soaVertexOffset))));
}
/// Get read only SOA unit normal vectors. This is an array of normals with all x values,
/// y values, and z values as separate arrays. The array lengths are padded to
/// a multiple of 4. The padded values are repeats of the first value.
pub fn b3GetHullSoaNormals(arg_hull: [*c]const b3HullData) callconv(.c) [*c]const f32 {
    var hull = arg_hull;
    _ = &hull;
    if (hull.*.soaNormalOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(hull))) + @as(isize, hull.*.soaNormalOffset))));
}
/// Create a tessellated cylinder as a hull.
pub extern fn b3CreateCylinder(height: f32, radius: f32, yOffset: f32, sides: c_int) [*c]b3HullData;
/// Create a tessellated cone as a hull.
pub extern fn b3CreateCone(height: f32, radius1: f32, radius2: f32, slices: c_int) [*c]b3HullData;
/// Create a rock shaped hull.
pub extern fn b3CreateRock(radius: f32) [*c]b3HullData;
/// Create a generic convex hull.
pub extern fn b3CreateHull(points: [*c]const b3Vec3, pointCount: c_int, maxVertexCount: c_int) [*c]b3HullData;
/// Deep clone a hull.
pub extern fn b3CloneHull(hull: [*c]const b3HullData) [*c]b3HullData;
/// Clone and transform a hull. Supports non-uniform and mirroring scale.
pub extern fn b3CloneAndTransformHull(original: [*c]const b3HullData, transform: b3Transform, scale: b3Vec3) [*c]b3HullData;
/// Destroy a hull.
pub extern fn b3DestroyHull(hull: [*c]b3HullData) void;
/// Make a cube as a hull. Do not call b3DestroyHull on this.
pub extern fn b3MakeCubeHull(halfWidth: f32) b3BoxHull;
/// Make a box as a hull. Do not call b3DestroyHull on this.
pub extern fn b3MakeBoxHull(hx: f32, hy: f32, hz: f32) b3BoxHull;
/// Make an offset box as a hull. Do not call b3DestroyHull on this.
pub extern fn b3MakeOffsetBoxHull(hx: f32, hy: f32, hz: f32, offset: b3Vec3) b3BoxHull;
/// Make a transformed box as a hull. Do not call b3DestroyHull on this.
/// @param hx, hy, hz positive half widths
/// @param transform local transform of box
pub extern fn b3MakeTransformedBoxHull(hx: f32, hy: f32, hz: f32, transform: b3Transform) b3BoxHull;
/// This makes a transformed box hull with post scaling. This is useful for boxes that are scaled in
/// a level editor. Such scaling can have reflection and shear. In the case of shear the result
/// may be approximate. If you need to support shear consider using b3CreateHull.
/// Do not call b3DestroyHull on this.
/// @param halfWidths positive half widths
/// @param transform local transform of box
/// @param postScale scale applied after the transform, may be negative
pub extern fn b3MakeScaledBoxHull(halfWidths: b3Vec3, transform: b3Transform, postScale: b3Vec3) b3BoxHull;
/// This takes a box with a transform and post scale and converts it into a box with the post scale
/// resolved with new half-widths and transform. This accepts non-uniform and negative scale.
/// This is approximate if there is shear.
/// @param halfWidths [in/out] the box half widths
/// @param transform [in/out] the box transform with rotation and translation
/// @param postScale the post scale being applied to the box after the transform
/// @param minHalfWidth the minimum half width after scale is applied
pub extern fn b3ScaleBox(halfWidths: [*c]b3Vec3, transform: [*c]b3Transform, postScale: b3Vec3, minHalfWidth: f32) void;
/// Get read only mesh BVH nodes.
pub fn b3GetMeshNodes(arg_mesh: [*c]const b3MeshData) callconv(.c) ?*const b3MeshNode {
    var mesh = arg_mesh;
    _ = &mesh;
    if (mesh.*.nodeOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(mesh))) + @as(isize, mesh.*.nodeOffset))));
}
/// Get read only mesh vertices.
pub fn b3GetMeshVertices(arg_mesh: [*c]const b3MeshData) callconv(.c) [*c]const b3Vec3 {
    var mesh = arg_mesh;
    _ = &mesh;
    if (mesh.*.vertexOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(mesh))) + @as(isize, mesh.*.vertexOffset))));
}
/// Get read only mesh triangles.
pub fn b3GetMeshTriangles(arg_mesh: [*c]const b3MeshData) callconv(.c) [*c]const b3MeshTriangle {
    var mesh = arg_mesh;
    _ = &mesh;
    if (mesh.*.triangleOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(mesh))) + @as(isize, mesh.*.triangleOffset))));
}
/// Get read only mesh materials. The count is equal to the triangle count.
pub fn b3GetMeshMaterialIndices(arg_mesh: [*c]const b3MeshData) callconv(.c) [*c]const u8 {
    var mesh = arg_mesh;
    _ = &mesh;
    if (mesh.*.materialOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(mesh))) + @as(isize, mesh.*.materialOffset))));
}
/// Get read only mesh flags. The count is equal to the triangle count.
pub fn b3GetMeshFlags(arg_mesh: [*c]const b3MeshData) callconv(.c) [*c]const u8 {
    var mesh = arg_mesh;
    _ = &mesh;
    if (mesh.*.flagsOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(mesh))) + @as(isize, mesh.*.flagsOffset))));
}
/// Create a grid mesh along the x and z axes.
/// @param xCount the number of rows in the x direction
/// @param zCount the number of rows in the z direction
/// @param cellWidth the width of each cell
/// @param materialCount the number of materials to generate
/// @param identifyEdges compute adjacency information
pub extern fn b3CreateGridMesh(xCount: c_int, zCount: c_int, cellWidth: f32, materialCount: c_int, identifyEdges: bool) [*c]b3MeshData;
/// Create a wave mesh along the x and z axes.
pub extern fn b3CreateWaveMesh(xCount: c_int, zCount: c_int, cellWidth: f32, amplitude: f32, rowFrequency: f32, columnFrequency: f32) [*c]b3MeshData;
/// Create a torus mesh.
pub extern fn b3CreateTorusMesh(radialResolution: c_int, tubularResolution: c_int, radius: f32, thickness: f32) [*c]b3MeshData;
/// Create a box mesh.
pub extern fn b3CreateBoxMesh(center: b3Vec3, extent: b3Vec3, identifyEdges: bool) [*c]b3MeshData;
/// Create a hollow box mesh.
pub extern fn b3CreateHollowBoxMesh(center: b3Vec3, extent: b3Vec3) [*c]b3MeshData;
/// Create a platform mesh. A truncated pyramid.
pub extern fn b3CreatePlatformMesh(center: b3Vec3, height: f32, topWidth: f32, bottomWidth: f32) [*c]b3MeshData;
/// Create a generic mesh.
pub extern fn b3CreateMesh(def: [*c]const b3MeshDef, degenerateTriangleIndices: [*c]c_int, degenerateCapacity: c_int) [*c]b3MeshData;
/// Destroy a mesh.
pub extern fn b3DestroyMesh(mesh: [*c]b3MeshData) void;
/// Get the height of the mesh BVH.
pub extern fn b3GetHeight(mesh: [*c]const b3MeshData) c_int;
/// Get read only compressed heights. One uint16_t per grid point.
pub fn b3GetHeightFieldCompressedHeights(arg_hf: [*c]const b3HeightFieldData) callconv(.c) [*c]const u16 {
    var hf = arg_hf;
    _ = &hf;
    if (hf.*.heightsOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(hf))) + @as(isize, hf.*.heightsOffset))));
}
/// Get read only material indices. One uint8_t per cell.
pub fn b3GetHeightFieldMaterialIndices(arg_hf: [*c]const b3HeightFieldData) callconv(.c) [*c]const u8 {
    var hf = arg_hf;
    _ = &hf;
    if (hf.*.materialOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(hf))) + @as(isize, hf.*.materialOffset))));
}
/// Get read only triangle flags. One uint8_t per triangle.
pub fn b3GetHeightFieldFlags(arg_hf: [*c]const b3HeightFieldData) callconv(.c) [*c]const u8 {
    var hf = arg_hf;
    _ = &hf;
    if (hf.*.flagsOffset == @as(c_int, 0)) {
        return null;
    }
    return @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(@intFromPtr(hf))) + @as(isize, hf.*.flagsOffset))));
}
/// Create a generic height field.
pub extern fn b3CreateHeightField(data: [*c]const b3HeightFieldDef) [*c]b3HeightFieldData;
/// Create a grid as a height field.
pub extern fn b3CreateGrid(rowCount: c_int, columnCount: c_int, scale: b3Vec3, makeHoles: bool) [*c]b3HeightFieldData;
/// Create a wave grid as a height field.
pub extern fn b3CreateWave(rowCount: c_int, columnCount: c_int, scale: b3Vec3, rowFrequency: f32, columnFrequency: f32, makeHoles: bool) [*c]b3HeightFieldData;
/// Destroy a height field.
pub extern fn b3DestroyHeightField(heightField: [*c]b3HeightFieldData) void;
/// Save input height data to a file
pub extern fn b3DumpHeightData(data: [*c]const b3HeightFieldDef, fileName: [*c]const u8) void;
/// Create a height field by loading a previously saved height data
pub extern fn b3LoadHeightField(fileName: [*c]const u8) [*c]b3HeightFieldData;
/// Get a child shape of a compound.
pub extern fn b3GetCompoundChild(compound: [*c]const b3CompoundData, childIndex: c_int) b3ChildShape;
/// Query a compound shape for children that overlap an AABB.
pub extern fn b3QueryCompound(compound: [*c]const b3CompoundData, aabb: b3AABB, fcn: ?*const b3CompoundQueryFcn, context: ?*anyopaque) void;
/// Access a child capsule by index.
pub extern fn b3GetCompoundCapsule(compound: [*c]const b3CompoundData, index: c_int) b3CompoundCapsule;
/// Access a child hull by index.
pub extern fn b3GetCompoundHull(compound: [*c]const b3CompoundData, index: c_int) b3CompoundHull;
/// Access a child mesh by index.
pub extern fn b3GetCompoundMesh(compound: [*c]const b3CompoundData, index: c_int) b3CompoundMesh;
/// Access a child sphere by index.
pub extern fn b3GetCompoundSphere(compound: [*c]const b3CompoundData, index: c_int) b3CompoundSphere;
/// Access the compound material array.
pub extern fn b3GetCompoundMaterials(compound: [*c]const b3CompoundData) [*c]const b3SurfaceMaterial;
/// Create a compound shape. All input data in the definition is cloned into the resulting compound.
pub extern fn b3CreateCompound(def: [*c]const b3CompoundDef) [*c]b3CompoundData;
/// Destroy a compound shape.
pub extern fn b3DestroyCompound(compound: [*c]b3CompoundData) void;
/// Cast the provided compound data to bytes, setting the internal pointers to null.
/// Use this before serializing the compound bytes.
pub extern fn b3ConvertCompoundToBytes(compound: [*c]b3CompoundData) [*c]u8;
/// Cast the provided bytes to compound data, setting up internal pointers.
/// Use this after de-serializing the compound bytes.
pub extern fn b3ConvertBytesToCompound(bytes: [*c]u8, byteCount: c_int) [*c]b3CompoundData;
/// Compute mass properties of a sphere
pub extern fn b3ComputeSphereMass(shape: [*c]const b3Sphere, density: f32) b3MassData;
/// Compute mass properties of a capsule
pub extern fn b3ComputeCapsuleMass(shape: [*c]const b3Capsule, density: f32) b3MassData;
/// Compute mass properties of a hull
pub extern fn b3ComputeHullMass(shape: [*c]const b3HullData, density: f32) b3MassData;
/// Compute the bounding box of a transformed sphere
pub extern fn b3ComputeSphereAABB(shape: [*c]const b3Sphere, transform: b3Transform) b3AABB;
/// Compute the bounding box of a transformed capsule
pub extern fn b3ComputeCapsuleAABB(shape: [*c]const b3Capsule, transform: b3Transform) b3AABB;
/// Compute the bounding box of a transformed hull
pub extern fn b3ComputeHullAABB(shape: [*c]const b3HullData, transform: b3Transform) b3AABB;
/// Compute the bounding box of a transformed mesh. Scale may be non-uniform and have negative components.
pub extern fn b3ComputeMeshAABB(shape: [*c]const b3MeshData, transform: b3Transform, scale: b3Vec3) b3AABB;
/// Compute the bounding box of a transformed height-field
pub extern fn b3ComputeHeightFieldAABB(shape: [*c]const b3HeightFieldData, transform: b3Transform) b3AABB;
/// Compute the bounding box of a compound
pub extern fn b3ComputeCompoundAABB(shape: [*c]const b3CompoundData, transform: b3Transform) b3AABB;
/// Use this to ensure your ray cast input is valid and avoid internal assertions.
pub extern fn b3IsValidRay(input: [*c]const b3RayCastInput) bool;
/// Overlap shape versus capsule
pub extern fn b3OverlapCapsule(shape: [*c]const b3Capsule, shapeTransform: b3Transform, proxy: [*c]const b3ShapeProxy) bool;
/// Overlap shape versus compound
pub extern fn b3OverlapCompound(shape: [*c]const b3CompoundData, shapeTransform: b3Transform, proxy: [*c]const b3ShapeProxy) bool;
/// Overlap shape versus height field
pub extern fn b3OverlapHeightField(shape: [*c]const b3HeightFieldData, shapeTransform: b3Transform, proxy: [*c]const b3ShapeProxy) bool;
/// Overlap shape versus hull
pub extern fn b3OverlapHull(shape: [*c]const b3HullData, shapeTransform: b3Transform, proxy: [*c]const b3ShapeProxy) bool;
/// Overlap shape versus mesh
pub extern fn b3OverlapMesh(shape: [*c]const b3Mesh, shapeTransform: b3Transform, proxy: [*c]const b3ShapeProxy) bool;
/// Overlap shape versus sphere
pub extern fn b3OverlapSphere(shape: [*c]const b3Sphere, shapeTransform: b3Transform, proxy: [*c]const b3ShapeProxy) bool;
/// Ray cast versus sphere in local space. A zero length ray is a point query. Initial overlap
/// reports a hit at the ray origin with zero fraction and zero normal.
pub extern fn b3RayCastSphere(shape: [*c]const b3Sphere, input: [*c]const b3RayCastInput) b3CastOutput;
/// Ray cast versus a hollow sphere shell in local space. Unlike the solid sphere a ray starting
/// inside is not an overlap: it passes through and hits the far wall.
pub extern fn b3RayCastHollowSphere(shape: [*c]const b3Sphere, input: [*c]const b3RayCastInput) b3CastOutput;
/// Ray cast versus capsule in local space. A zero length ray is a point query. Initial overlap
/// reports a hit at the ray origin with zero fraction and zero normal.
pub extern fn b3RayCastCapsule(shape: [*c]const b3Capsule, input: [*c]const b3RayCastInput) b3CastOutput;
/// Ray cast versus compound in local space. A zero length ray is a point query. Initial overlap
/// with a child reports a hit at the ray origin with zero fraction and zero normal.
pub extern fn b3RayCastCompound(shape: [*c]const b3CompoundData, input: [*c]const b3RayCastInput) b3CastOutput;
/// Ray cast versus hull shape in local space. A zero length ray is a point query. Initial overlap
/// reports a hit at the ray origin with zero fraction and zero normal.
pub extern fn b3RayCastHull(shape: [*c]const b3HullData, input: [*c]const b3RayCastInput) b3CastOutput;
/// Ray cast versus mesh in local space. A thin surface with no interior, so there is no overlap case.
pub extern fn b3RayCastMesh(shape: [*c]const b3Mesh, input: [*c]const b3RayCastInput) b3CastOutput;
/// Ray cast versus height field in local space. A thin surface with no interior, so there is no overlap case.
pub extern fn b3RayCastHeightField(shape: [*c]const b3HeightFieldData, input: [*c]const b3RayCastInput) b3CastOutput;
/// Shape cast versus a sphere. Initial overlap is treated as a miss.
pub extern fn b3ShapeCastSphere(shape: [*c]const b3Sphere, input: [*c]const b3ShapeCastInput) b3CastOutput;
/// Shape cast versus a capsule. Initial overlap is treated as a miss.
pub extern fn b3ShapeCastCapsule(shape: [*c]const b3Capsule, input: [*c]const b3ShapeCastInput) b3CastOutput;
/// Shape cast versus compound. Initial overlap is treated as a miss.
pub extern fn b3ShapeCastCompound(shape: [*c]const b3CompoundData, input: [*c]const b3ShapeCastInput) b3CastOutput;
/// Shape cast versus a hull. Initial overlap is treated as a miss.
pub extern fn b3ShapeCastHull(shape: [*c]const b3HullData, input: [*c]const b3ShapeCastInput) b3CastOutput;
/// Shape cast versus a mesh. Initial overlap is treated as a miss.
pub extern fn b3ShapeCastMesh(shape: [*c]const b3Mesh, input: [*c]const b3ShapeCastInput) b3CastOutput;
/// Shape cast versus a height field. Initial overlap is treated as a miss.
pub extern fn b3ShapeCastHeightField(shape: [*c]const b3HeightFieldData, input: [*c]const b3ShapeCastInput) b3CastOutput;
/// Query callback.
pub const b3MeshQueryFcn = fn (a: b3Vec3, b: b3Vec3, c: b3Vec3, triangleIndex: c_int, context: ?*anyopaque) callconv(.c) bool;
/// Query a mesh for triangles overlapping a bounding box in local space. May have false positives. Useful for debug draw.
/// @param mesh the mesh to query, includes scale
/// @param bounds the bounding box in local space
/// @param fcn a user function to collect triangles
/// @param context the context sent to the user function.
pub extern fn b3QueryMesh(mesh: [*c]const b3Mesh, bounds: b3AABB, fcn: ?*const b3MeshQueryFcn, context: ?*anyopaque) void;
/// Query a height field for triangles overlapping a bounding box in local space. May have false positives. Useful for debug draw.
/// @param heightField the height field to query
/// @param bounds the bounding box in local space
/// @param fcn a user function to collect triangles
/// @param context the context sent to the user function.
pub extern fn b3QueryHeightField(heightField: [*c]const b3HeightFieldData, bounds: b3AABB, fcn: ?*const b3MeshQueryFcn, context: ?*anyopaque) void;
/// Compute the closest points between two shapes represented as point clouds.
/// b3SimplexCache cache is input/output. On the first call set b3SimplexCache.count to zero.
/// The query runs in frame A, so the witness points and normal are returned in frame A.
/// The underlying GJK algorithm may be debugged by passing in debug simplexes and capacity. You may pass in NULL and 0 for these.
pub extern fn b3ShapeDistance(input: [*c]const b3DistanceInput, cache: [*c]b3SimplexCache, simplexes: [*c]b3Simplex, simplexCapacity: c_int) b3DistanceOutput;
/// Perform a linear shape cast of shape B moving and shape A fixed. Determines the hit point, normal, and translation fraction.
/// The query runs in frame A, so the hit point and normal are returned in frame A. Initially touching shapes are a miss.
pub extern fn b3ShapeCast(input: [*c]const b3ShapeCastPairInput) b3CastOutput;
/// Evaluate the transform sweep at a specific time.
pub extern fn b3GetSweepTransform(sweep: [*c]const b3Sweep, time: f32) b3Transform;
/// Compute the upper bound on time before two shapes penetrate. Time is represented as
/// a fraction between [0,tMax]. This uses a swept separating axis and may miss some intermediate,
/// non-tunneling collisions. If you change the time interval, you should call this function
/// again.
pub extern fn b3TimeOfImpact(input: [*c]const b3TOIInput) b3TOIOutput;
/// Collide two spheres.
pub extern fn b3CollideSpheres(manifold: [*c]b3LocalManifold, capacity: c_int, sphereA: [*c]const b3Sphere, sphereB: [*c]const b3Sphere, transformBtoA: b3Transform) void;
/// Collide a capsule and a sphere.
pub extern fn b3CollideCapsuleAndSphere(manifold: [*c]b3LocalManifold, capacity: c_int, capsuleA: [*c]const b3Capsule, sphereB: [*c]const b3Sphere, transformBtoA: b3Transform) void;
/// Collide a hull and a sphere.
pub extern fn b3CollideHullAndSphere(manifold: [*c]b3LocalManifold, capacity: c_int, hullA: [*c]const b3HullData, sphereB: [*c]const b3Sphere, transformBtoA: b3Transform, cache: [*c]b3SimplexCache) void;
/// Collide two capsules.
pub extern fn b3CollideCapsules(manifold: [*c]b3LocalManifold, capacity: c_int, capsuleA: [*c]const b3Capsule, capsuleB: [*c]const b3Capsule, transformBtoA: b3Transform) void;
/// Collide a hull and a capsule.
pub extern fn b3CollideHullAndCapsule(manifold: [*c]b3LocalManifold, capacity: c_int, hullA: [*c]const b3HullData, capsuleB: [*c]const b3Capsule, transformBtoA: b3Transform, cache: [*c]b3SimplexCache) void;
/// Collide two hulls.
pub extern fn b3CollideHulls(manifold: [*c]b3LocalManifold, capacity: c_int, hullA: [*c]const b3HullData, hullB: [*c]const b3HullData, transformBtoA: b3Transform, cache: [*c]b3SATCache) void;
/// Collide a triangle and capsule. Normal points from triangle to capsule.
pub extern fn b3CollideTriangleAndCapsule(manifold: [*c]b3LocalManifold, capacity: c_int, triangleA: [*c]const b3Vec3, capsuleB: [*c]const b3Capsule, cache: [*c]b3SimplexCache) void;
/// Collide a triangle and hull. Normal points from triangle to hull.
pub extern fn b3CollideTriangleAndHull(manifold: [*c]b3LocalManifold, capacity: c_int, v1: b3Vec3, v2: b3Vec3, v3: b3Vec3, triangleFlags: c_int, hullB: [*c]const b3HullData, cache: [*c]b3SATCache, enableSpeculative: bool) void;
/// Collide a triangle and sphere. Normal points from triangle to sphere.
pub extern fn b3CollideTriangleAndSphere(manifold: [*c]b3LocalManifold, capacity: c_int, triangleA: [*c]const b3Vec3, sphereB: [*c]const b3Sphere) void;
/// Solves the position of a mover that satisfies the given collision planes.
/// @param targetDelta the desired translation from the position used to generate the collision planes
/// @param planes the collision planes
/// @param count the number of collision planes
pub extern fn b3SolvePlanes(targetDelta: b3Vec3, planes: [*c]b3CollisionPlane, count: c_int) b3PlaneSolverResult;
/// Clips the velocity against the given collision planes. Planes with zero push or clipVelocity
/// set to false are skipped.
pub extern fn b3ClipVector(vector: b3Vec3, planes: [*c]const b3CollisionPlane, count: c_int) b3Vec3;
/// Create a world for rigid body simulation. A world contains bodies, shapes, and constraints. You may create
/// up to 128 worlds. Each world is completely independent and may be simulated in parallel.
/// @return the world id.
pub extern fn b3CreateWorld(def: [*c]const b3WorldDef) b3WorldId;
/// Destroy a world
pub extern fn b3DestroyWorld(worldId: b3WorldId) void;
/// Get the current number of worlds
pub extern fn b3GetWorldCount() c_int;
/// Get the maximum number of simultaneous worlds that have been created
pub extern fn b3GetMaxWorldCount() c_int;
/// World id validation. Provides validation for up to 64K allocations.
pub extern fn b3World_IsValid(id: b3WorldId) bool;
/// Simulate a world for one time step. This performs collision detection, integration, and constraint solution.
/// @param worldId The world to simulate
/// @param timeStep The amount of time to simulate, this should be a fixed number. Usually 1/60.
/// @param subStepCount The number of sub-steps, increasing the sub-step count can increase accuracy. Usually 4.
pub extern fn b3World_Step(worldId: b3WorldId, timeStep: f32, subStepCount: c_int) void;
/// Call this to draw shapes and other debug draw data
pub extern fn b3World_Draw(worldId: b3WorldId, draw: [*c]b3DebugDraw, maskBits: u64) void;
/// Get the world's bounds. This is the bounding box that covers the current simulation. May have a small
/// amount of padding.
pub extern fn b3World_GetBounds(worldId: b3WorldId) b3AABB;
/// Get the body events for the current time step. The event data is transient. Do not store a reference to this data.
pub extern fn b3World_GetBodyEvents(worldId: b3WorldId) b3BodyEvents;
/// Get sensor events for the current time step. The event data is transient. Do not store a reference to this data.
pub extern fn b3World_GetSensorEvents(worldId: b3WorldId) b3SensorEvents;
/// Get contact events for this current time step. The event data is transient. Do not store a reference to this data.
pub extern fn b3World_GetContactEvents(worldId: b3WorldId) b3ContactEvents;
/// Get the joint events for the current time step. The event data is transient. Do not store a reference to this data.
pub extern fn b3World_GetJointEvents(worldId: b3WorldId) b3JointEvents;
/// Overlap test for all shapes that *potentially* overlap the provided AABB
pub extern fn b3World_OverlapAABB(worldId: b3WorldId, aabb: b3AABB, filter: b3QueryFilter, fcn: ?*const b3OverlapResultFcn, context: ?*anyopaque) b3TreeStats;
/// Overlap test for all shapes that overlap the provided shape proxy. The proxy points are relative
/// to the world origin, which lets the query stay precise far from the world origin.
pub extern fn b3World_OverlapShape(worldId: b3WorldId, origin: b3Pos, proxy: [*c]const b3ShapeProxy, filter: b3QueryFilter, fcn: ?*const b3OverlapResultFcn, context: ?*anyopaque) b3TreeStats;
/// Cast a ray into the world to collect shapes in the path of the ray.
/// Your callback function controls whether you get the closest point, any point, or n-points.
/// @note The callback function may receive shapes in any order
/// @param worldId The world to cast the ray against
/// @param origin The start point of the ray
/// @param translation The translation of the ray from the start point to the end point
/// @param filter Contains bit flags to filter unwanted shapes from the results
/// @param fcn A user implemented callback function
/// @param context A user context that is passed along to the callback function
/// @return traversal performance counters
pub extern fn b3World_CastRay(worldId: b3WorldId, origin: b3Pos, translation: b3Vec3, filter: b3QueryFilter, fcn: ?*const b3CastResultFcn, context: ?*anyopaque) b3TreeStats;
/// Cast a ray into the world to collect the closest hit. This is a convenience function. Ignores initial overlap.
/// This is less general than b3World_CastRay() and does not allow for custom filtering.
pub extern fn b3World_CastRayClosest(worldId: b3WorldId, origin: b3Pos, translation: b3Vec3, filter: b3QueryFilter) b3RayResult;
/// Cast a shape through the world. Similar to a cast ray except that a shape is cast instead of a point.
/// The proxy points are relative to the origin and the hit points come back as world positions, so the
/// cast stays precise far from the world origin.
/// @see b3World_CastRay
pub extern fn b3World_CastShape(worldId: b3WorldId, origin: b3Pos, proxy: [*c]const b3ShapeProxy, translation: b3Vec3, filter: b3QueryFilter, fcn: ?*const b3CastResultFcn, context: ?*anyopaque) b3TreeStats;
/// Cast a capsule mover through the world. This is a special shape cast that handles sliding along other shapes while reducing
/// clipping. This is not a good source of information about what the mover is touching. Instead use the planes returned by
/// b3World_CollideMover.
/// @param worldId World to cast the mover against
/// @param origin World position the mover capsule is relative to
/// @param mover Capsule mover, relative to the origin
/// @param translation Desired mover translation
/// @param filter Contains bit flags to filter unwanted shapes from the results
/// @param fcn Optional callback for custom shape filtering
/// @param context A user context that is passed along to the callback function
/// @return the translation fraction
pub extern fn b3World_CastMover(worldId: b3WorldId, origin: b3Pos, mover: [*c]const b3Capsule, translation: b3Vec3, filter: b3QueryFilter, fcn: ?*const b3MoverFilterFcn, context: ?*anyopaque) f32;
/// Collide a capsule mover with the world, gathering collision planes that can be fed to b3SolvePlanes. Useful for
/// kinematic character movement. The mover and the returned planes are relative to the origin.
pub extern fn b3World_CollideMover(worldId: b3WorldId, origin: b3Pos, mover: [*c]const b3Capsule, filter: b3QueryFilter, fcn: ?*const b3PlaneResultFcn, context: ?*anyopaque) void;
/// Enable/disable sleep. If your application does not need sleeping, you can gain some performance
/// by disabling sleep completely at the world level.
/// @see b3WorldDef
pub extern fn b3World_EnableSleeping(worldId: b3WorldId, flag: bool) void;
/// Is body sleeping enabled?
pub extern fn b3World_IsSleepingEnabled(worldId: b3WorldId) bool;
/// Enable/disable continuous collision between dynamic and static bodies. Generally you should keep continuous
/// collision enabled to prevent fast moving objects from going through static objects. The performance gain from
/// disabling continuous collision is minor.
/// @see b3WorldDef
pub extern fn b3World_EnableContinuous(worldId: b3WorldId, flag: bool) void;
/// Is continuous collision enabled?
pub extern fn b3World_IsContinuousEnabled(worldId: b3WorldId) bool;
/// Adjust the restitution threshold. It is recommended not to make this value very small
/// because it will prevent bodies from sleeping. Usually in meters per second.
/// @see b3WorldDef
pub extern fn b3World_SetRestitutionThreshold(worldId: b3WorldId, value: f32) void;
/// Get the restitution speed threshold. Usually in meters per second.
pub extern fn b3World_GetRestitutionThreshold(worldId: b3WorldId) f32;
/// Adjust the hit event threshold. This controls the collision speed needed to generate a b3ContactHitEvent.
/// Usually in meters per second.
/// @see b3WorldDef::hitEventThreshold
pub extern fn b3World_SetHitEventThreshold(worldId: b3WorldId, value: f32) void;
/// Get the hit event speed threshold. Usually in meters per second.
pub extern fn b3World_GetHitEventThreshold(worldId: b3WorldId) f32;
/// Register the custom filter callback. This is optional.
pub extern fn b3World_SetCustomFilterCallback(worldId: b3WorldId, fcn: ?*const b3CustomFilterFcn, context: ?*anyopaque) void;
/// Register the pre-solve callback. This is optional.
pub extern fn b3World_SetPreSolveCallback(worldId: b3WorldId, fcn: ?*const b3PreSolveFcn, context: ?*anyopaque) void;
/// Set the gravity vector for the entire world. Box3D has no concept of an up direction and this
/// is left as a decision for the application. Usually in m/s^2.
/// @see b3WorldDef
pub extern fn b3World_SetGravity(worldId: b3WorldId, gravity: b3Vec3) void;
/// Get the gravity vector
pub extern fn b3World_GetGravity(worldId: b3WorldId) b3Vec3;
/// Apply a radial explosion
/// @param worldId The world id
/// @param explosionDef The explosion definition
pub extern fn b3World_Explode(worldId: b3WorldId, explosionDef: [*c]const b3ExplosionDef) void;
/// Adjust contact tuning parameters
/// @param worldId The world id
/// @param hertz The contact stiffness (cycles per second)
/// @param dampingRatio The contact bounciness with 1 being critical damping (non-dimensional)
/// @param contactSpeed The maximum contact constraint push out speed (meters per second)
/// @note Advanced feature
pub extern fn b3World_SetContactTuning(worldId: b3WorldId, hertz: f32, dampingRatio: f32, contactSpeed: f32) void;
/// Set the contact point recycling distance. Setting this to zero disables contact point recycling.
/// Usually in meters.
pub extern fn b3World_SetContactRecycleDistance(worldId: b3WorldId, recycleDistance: f32) void;
/// Get the contact point recycling distance. Usually in meters.
pub extern fn b3World_GetContactRecycleDistance(worldId: b3WorldId) f32;
/// Set the maximum linear speed. Usually in m/s.
pub extern fn b3World_SetMaximumLinearSpeed(worldId: b3WorldId, maximumLinearSpeed: f32) void;
/// Get the maximum linear speed. Usually in m/s.
pub extern fn b3World_GetMaximumLinearSpeed(worldId: b3WorldId) f32;
/// Enable/disable constraint warm starting. Advanced feature for testing. Disabling
/// warm starting greatly reduces stability and provides no performance gain.
pub extern fn b3World_EnableWarmStarting(worldId: b3WorldId, flag: bool) void;
/// Is constraint warm starting enabled?
pub extern fn b3World_IsWarmStartingEnabled(worldId: b3WorldId) bool;
/// Get the number of awake bodies
pub extern fn b3World_GetAwakeBodyCount(worldId: b3WorldId) c_int;
/// Get the current world performance profile
pub extern fn b3World_GetProfile(worldId: b3WorldId) b3Profile;
/// Get world counters and sizes
pub extern fn b3World_GetCounters(worldId: b3WorldId) b3Counters;
/// Get max capacity. This can be used with b3WorldDef to avoid run-time allocations and copies
pub extern fn b3World_GetMaxCapacity(worldId: b3WorldId) b3Capacity;
/// Set the user data pointer.
pub extern fn b3World_SetUserData(worldId: b3WorldId, userData: ?*anyopaque) void;
/// Get the user data pointer.
pub extern fn b3World_GetUserData(worldId: b3WorldId) ?*anyopaque;
/// Set the friction callback. Passing NULL resets to default.
pub extern fn b3World_SetFrictionCallback(worldId: b3WorldId, callback: ?*const b3FrictionCallback) void;
/// Set the restitution callback. Passing NULL resets to default.
pub extern fn b3World_SetRestitutionCallback(worldId: b3WorldId, callback: ?*const b3RestitutionCallback) void;
/// Set the worker count. Must be in the range [1, B3_MAX_WORKERS]
pub extern fn b3World_SetWorkerCount(worldId: b3WorldId, count: c_int) void;
/// Get the worker count.
pub extern fn b3World_GetWorkerCount(worldId: b3WorldId) c_int;
/// Dump memory stats to log.
pub extern fn b3World_DumpMemoryStats(worldId: b3WorldId) void;
/// Dump shape bounds to box3d_bounds.txt
pub extern fn b3World_DumpShapeBounds(worldId: b3WorldId, @"type": b3BodyType) void;
/// This is for internal testing
pub extern fn b3World_RebuildStaticTree(worldId: b3WorldId) void;
/// This is for internal testing
pub extern fn b3World_EnableSpeculative(worldId: b3WorldId, flag: bool) void;
pub const struct_b3Recording = opaque {
    /// Destroy a recording and free its buffer.
    /// @param recording may be NULL
    pub const b3DestroyRecording = __root.b3DestroyRecording;
    /// Get a pointer to the raw recording bytes.
    /// Valid until the recording buffer is modified or destroyed.
    /// @param recording the recording handle
    /// @return pointer to the byte buffer, or NULL if no bytes have been written
    pub const b3Recording_GetData = __root.b3Recording_GetData;
    /// Get the number of bytes currently in the recording buffer.
    /// @param recording the recording handle
    pub const b3Recording_GetSize = __root.b3Recording_GetSize;
    /// Save the recording buffer to a file. Returns true on success.
    /// @param recording the recording to save
    /// @param path file path to write
    pub const b3SaveRecordingToFile = __root.b3SaveRecordingToFile;
    pub const GetData = __root.b3Recording_GetData;
    pub const GetSize = __root.b3Recording_GetSize;
};
/// Opaque recording handle. Create with b3CreateRecording, destroy with b3DestroyRecording.
pub const b3Recording = struct_b3Recording;
/// Create a recording buffer with an optional initial byte capacity.
/// Pass 0 to use the default (64 KiB). The buffer grows on demand.
/// @return a new recording, owned by the caller
pub extern fn b3CreateRecording(byteCapacity: c_int) ?*b3Recording;
/// Destroy a recording and free its buffer.
/// @param recording may be NULL
pub extern fn b3DestroyRecording(recording: ?*b3Recording) void;
/// Get a pointer to the raw recording bytes.
/// Valid until the recording buffer is modified or destroyed.
/// @param recording the recording handle
/// @return pointer to the byte buffer, or NULL if no bytes have been written
pub extern fn b3Recording_GetData(recording: ?*const b3Recording) [*c]const u8;
/// Get the number of bytes currently in the recording buffer.
/// @param recording the recording handle
pub extern fn b3Recording_GetSize(recording: ?*const b3Recording) c_int;
/// Begin recording world mutations into the provided buffer.
/// The buffer is reset on each call so a single b3Recording can be reused for multiple sessions.
/// @param worldId the world to record
/// @param recording the recording handle to write into
pub extern fn b3World_StartRecording(worldId: b3WorldId, recording: ?*b3Recording) void;
/// End the current recording session. Writes the trailing geometry registry and
/// backpatches the header. The buffer remains valid until the recording is destroyed.
/// @param worldId the world currently being recorded
pub extern fn b3World_StopRecording(worldId: b3WorldId) void;
/// Save the recording buffer to a file. Returns true on success.
/// @param recording the recording to save
/// @param path file path to write
pub extern fn b3SaveRecordingToFile(recording: ?*const b3Recording, path: [*c]const u8) bool;
/// Load a recording from a file. Returns NULL on failure (file not found, wrong magic).
/// The caller owns the returned recording and must destroy it with b3DestroyRecording.
/// @param path file path to read
pub extern fn b3LoadRecordingFromFile(path: [*c]const u8) ?*b3Recording;
/// Replay a recording from memory and verify it reproduces the same world-state hashes.
/// Stands up a fresh world, restores the seed snapshot, replays every op, and checks each embedded
/// StateHash record. Returns true if replay completed without id mismatches or hash divergences.
/// @param data pointer to recording bytes
/// @param size byte count of the recording
/// @param workerCount reserved for future multithreaded replay; pass 1 for now
pub extern fn b3ValidateReplay(data: ?*const anyopaque, size: c_int, workerCount: c_int) bool;
pub const struct_b3RecPlayer = opaque {
    /// Destroy the player and free all memory. Restores the previous global length scale.
    pub const b3RecPlayer_Destroy = __root.b3RecPlayer_Destroy;
    /// Advance one frame. dispatch ops until the next Step completes.
    /// @return true when a frame was stepped, false at end-of-recording
    pub const b3RecPlayer_StepFrame = __root.b3RecPlayer_StepFrame;
    /// Sub-step one frame. This will sub-step and return immediately after body creation.
    /// The next call will execute the time step. This allows bodies to be rendered
    /// at the creation pose.
    pub const b3RecPlayer_SubStepFrame = __root.b3RecPlayer_SubStepFrame;
    /// Rewind to frame 0 (in-place restore so the world id stays stable).
    pub const b3RecPlayer_Restart = __root.b3RecPlayer_Restart;
    /// Seek to a specific frame. Forward seek steps op-by-op; backward seek restores
    /// the nearest keyframe then re-steps the remaining gap.
    pub const b3RecPlayer_SeekFrame = __root.b3RecPlayer_SeekFrame;
    /// @return the world currently driven by this player
    pub const b3RecPlayer_GetWorldId = __root.b3RecPlayer_GetWorldId;
    /// @return the last fully-stepped frame index (0 before any step)
    pub const b3RecPlayer_GetFrame = __root.b3RecPlayer_GetFrame;
    /// @return total number of recorded frames
    pub const b3RecPlayer_GetFrameCount = __root.b3RecPlayer_GetFrameCount;
    /// @return true when the op stream is exhausted
    pub const b3RecPlayer_IsAtEnd = __root.b3RecPlayer_IsAtEnd;
    /// @return true when the op stream is paused between body creation and world step.
    pub const b3RecPlayer_IsAtPreStep = __root.b3RecPlayer_IsAtPreStep;
    /// @return true when any StateHash mismatch has been detected
    pub const b3RecPlayer_HasDiverged = __root.b3RecPlayer_HasDiverged;
    /// @return a summary of the recording read at open: frame count, recorded tuning, and bounds
    pub const b3RecPlayer_GetInfo = __root.b3RecPlayer_GetInfo;
    /// @return the first frame at which replay diverged, or -1 if it has not diverged
    pub const b3RecPlayer_GetDivergeFrame = __root.b3RecPlayer_GetDivergeFrame;
    /// Set the worker count of the replay world. Clamped to [1, B3_MAX_WORKERS]. Applied to the live
    /// world at once and reused whenever the player rebuilds its world on Restart or a backward seek.
    /// Replaying at a different count than recorded re-partitions the constraint graph, so the StateHash
    /// check becomes a cross-thread determinism test.
    pub const b3RecPlayer_SetWorkerCount = __root.b3RecPlayer_SetWorkerCount;
    /// Tune the keyframe ring used to speed up backward seeking. A keyframe is a periodic snapshot the
    /// player restores from instead of replaying from the start, trading memory for seek speed.
    /// @param player the recording player
    /// @param budgetBytes memory cap for the kept snapshots; the spacing widens to stay under it
    /// @param minIntervalFrames finest spacing between keyframes, in frames
    /// A zero budget or a non-positive interval keeps that value. Clears the existing ring, so call
    /// b3RecPlayer_Restart afterward to repopulate it under the new policy.
    pub const b3RecPlayer_SetKeyframePolicy = __root.b3RecPlayer_SetKeyframePolicy;
    /// @return the keyframe memory budget in bytes
    pub const b3RecPlayer_GetKeyframeBudget = __root.b3RecPlayer_GetKeyframeBudget;
    /// @return the finest keyframe spacing in frames
    pub const b3RecPlayer_GetKeyframeMinInterval = __root.b3RecPlayer_GetKeyframeMinInterval;
    /// @return the current keyframe spacing in frames; starts at the min interval and doubles as the
    /// ring evicts to stay under budget, so it reflects the effective backward-seek granularity now
    pub const b3RecPlayer_GetKeyframeInterval = __root.b3RecPlayer_GetKeyframeInterval;
    /// @return the memory currently held by keyframe snapshots, in bytes
    pub const b3RecPlayer_GetKeyframeBytes = __root.b3RecPlayer_GetKeyframeBytes;
    /// @return the number of bodies tracked in creation order (including holes for destroyed bodies)
    pub const b3RecPlayer_GetBodyCount = __root.b3RecPlayer_GetBodyCount;
    /// Resolve a creation ordinal to the live body id at the current frame.
    /// @return the body id, or a null id if that ordinal is out of range or its body is destroyed
    pub const b3RecPlayer_GetBodyId = __root.b3RecPlayer_GetBodyId;
    /// Wire host debug-shape callbacks into the player's replay world so a renderer can build
    /// per-shape draw resources (the 3D sample needs this or the replay world draws nothing).
    /// Rebuilds the current world under the new callbacks and rewinds to frame 0, so call it
    /// once right after b3RecPlayer_Create and re-read the world id afterward. The callbacks
    /// persist across Restart and backward seeks, which recreate the world internally.
    /// @param player the player to configure
    /// @param createDebugShape called when a replayed shape is added; returns a user draw handle
    /// @param destroyDebugShape called when a replayed shape is removed; may be NULL
    /// @param context user context passed to both callbacks
    pub const b3RecPlayer_SetDebugShapeCallbacks = __root.b3RecPlayer_SetDebugShapeCallbacks;
    /// Draw the spatial queries recorded during the most recently replayed frame, layered on top of the
    /// world. Call after b3World_Draw. NULL draw function pointers are skipped.
    /// @param player a valid player handle
    /// @param draw debug draw callbacks
    /// @param queryIndex index of the frame query to draw, or -1 to draw all of them
    /// @param selectedIndex index of the query to emphasize (reserved color plus a label), or -1 for none
    pub const b3RecPlayer_DrawFrameQueries = __root.b3RecPlayer_DrawFrameQueries;
    /// @return the number of spatial queries recorded for the most recently replayed frame
    pub const b3RecPlayer_GetFrameQueryCount = __root.b3RecPlayer_GetFrameQueryCount;
    /// Get a recorded query from the most recently replayed frame by index.
    pub const b3RecPlayer_GetFrameQuery = __root.b3RecPlayer_GetFrameQuery;
    /// Get one result of a recorded query from the most recently replayed frame.
    pub const b3RecPlayer_GetFrameQueryHit = __root.b3RecPlayer_GetFrameQueryHit;
    pub const Destroy = __root.b3RecPlayer_Destroy;
    pub const StepFrame = __root.b3RecPlayer_StepFrame;
    pub const SubStepFrame = __root.b3RecPlayer_SubStepFrame;
    pub const Restart = __root.b3RecPlayer_Restart;
    pub const SeekFrame = __root.b3RecPlayer_SeekFrame;
    pub const GetWorldId = __root.b3RecPlayer_GetWorldId;
    pub const GetFrame = __root.b3RecPlayer_GetFrame;
    pub const GetFrameCount = __root.b3RecPlayer_GetFrameCount;
    pub const IsAtEnd = __root.b3RecPlayer_IsAtEnd;
    pub const IsAtPreStep = __root.b3RecPlayer_IsAtPreStep;
    pub const HasDiverged = __root.b3RecPlayer_HasDiverged;
    pub const GetInfo = __root.b3RecPlayer_GetInfo;
    pub const GetDivergeFrame = __root.b3RecPlayer_GetDivergeFrame;
    pub const SetWorkerCount = __root.b3RecPlayer_SetWorkerCount;
    pub const SetKeyframePolicy = __root.b3RecPlayer_SetKeyframePolicy;
    pub const GetKeyframeBudget = __root.b3RecPlayer_GetKeyframeBudget;
    pub const GetKeyframeMinInterval = __root.b3RecPlayer_GetKeyframeMinInterval;
    pub const GetKeyframeInterval = __root.b3RecPlayer_GetKeyframeInterval;
    pub const GetKeyframeBytes = __root.b3RecPlayer_GetKeyframeBytes;
    pub const GetBodyCount = __root.b3RecPlayer_GetBodyCount;
    pub const GetBodyId = __root.b3RecPlayer_GetBodyId;
    pub const SetDebugShapeCallbacks = __root.b3RecPlayer_SetDebugShapeCallbacks;
    pub const DrawFrameQueries = __root.b3RecPlayer_DrawFrameQueries;
    pub const GetFrameQueryCount = __root.b3RecPlayer_GetFrameQueryCount;
    pub const GetFrameQuery = __root.b3RecPlayer_GetFrameQuery;
    pub const GetFrameQueryHit = __root.b3RecPlayer_GetFrameQueryHit;
};
/// Opaque incremental replay player with a keyframe ring for O(interval) backward seek.
pub const b3RecPlayer = struct_b3RecPlayer;
pub const struct_b3RecPlayerInfo = extern struct {
    frameCount: c_int = 0,
    workerCount: c_int = 0,
    timeStep: f32 = 0,
    subStepCount: c_int = 0,
    lengthScale: f32 = 0,
    bounds: b3AABB = @import("std").mem.zeroes(b3AABB),
};
/// Summary of a recording, read once at open so a viewer can frame and label it.
pub const b3RecPlayerInfo = struct_b3RecPlayerInfo;
/// Create a player over a recording. Owns a private copy of the bytes.
/// @param data pointer to recording bytes
/// @param size byte count of the recording
/// @param workerCount worker count for the replay world; pass 1 to match a serial recording.
/// Replaying at a different count re-partitions the constraint graph, so the StateHash check
/// becomes a cross-thread determinism test. Adjustable later with b3RecPlayer_SetWorkerCount.
/// @return a new player, or NULL on bad header or deserialization failure
pub extern fn b3RecPlayer_Create(data: ?*const anyopaque, size: c_int, workerCount: c_int) ?*b3RecPlayer;
/// Destroy the player and free all memory. Restores the previous global length scale.
pub extern fn b3RecPlayer_Destroy(player: ?*b3RecPlayer) void;
/// Advance one frame. dispatch ops until the next Step completes.
/// @return true when a frame was stepped, false at end-of-recording
pub extern fn b3RecPlayer_StepFrame(player: ?*b3RecPlayer) bool;
/// Sub-step one frame. This will sub-step and return immediately after body creation.
/// The next call will execute the time step. This allows bodies to be rendered
/// at the creation pose.
pub extern fn b3RecPlayer_SubStepFrame(player: ?*b3RecPlayer) void;
/// Rewind to frame 0 (in-place restore so the world id stays stable).
pub extern fn b3RecPlayer_Restart(player: ?*b3RecPlayer) void;
/// Seek to a specific frame. Forward seek steps op-by-op; backward seek restores
/// the nearest keyframe then re-steps the remaining gap.
pub extern fn b3RecPlayer_SeekFrame(player: ?*b3RecPlayer, targetFrame: c_int) void;
/// @return the world currently driven by this player
pub extern fn b3RecPlayer_GetWorldId(player: ?*const b3RecPlayer) b3WorldId;
/// @return the last fully-stepped frame index (0 before any step)
pub extern fn b3RecPlayer_GetFrame(player: ?*const b3RecPlayer) c_int;
/// @return total number of recorded frames
pub extern fn b3RecPlayer_GetFrameCount(player: ?*const b3RecPlayer) c_int;
/// @return true when the op stream is exhausted
pub extern fn b3RecPlayer_IsAtEnd(player: ?*const b3RecPlayer) bool;
/// @return true when the op stream is paused between body creation and world step.
pub extern fn b3RecPlayer_IsAtPreStep(player: ?*const b3RecPlayer) bool;
/// @return true when any StateHash mismatch has been detected
pub extern fn b3RecPlayer_HasDiverged(player: ?*const b3RecPlayer) bool;
/// @return a summary of the recording read at open: frame count, recorded tuning, and bounds
pub extern fn b3RecPlayer_GetInfo(player: ?*const b3RecPlayer) b3RecPlayerInfo;
/// @return the first frame at which replay diverged, or -1 if it has not diverged
pub extern fn b3RecPlayer_GetDivergeFrame(player: ?*const b3RecPlayer) c_int;
/// Set the worker count of the replay world. Clamped to [1, B3_MAX_WORKERS]. Applied to the live
/// world at once and reused whenever the player rebuilds its world on Restart or a backward seek.
/// Replaying at a different count than recorded re-partitions the constraint graph, so the StateHash
/// check becomes a cross-thread determinism test.
pub extern fn b3RecPlayer_SetWorkerCount(player: ?*b3RecPlayer, count: c_int) void;
/// Tune the keyframe ring used to speed up backward seeking. A keyframe is a periodic snapshot the
/// player restores from instead of replaying from the start, trading memory for seek speed.
/// @param player the recording player
/// @param budgetBytes memory cap for the kept snapshots; the spacing widens to stay under it
/// @param minIntervalFrames finest spacing between keyframes, in frames
/// A zero budget or a non-positive interval keeps that value. Clears the existing ring, so call
/// b3RecPlayer_Restart afterward to repopulate it under the new policy.
pub extern fn b3RecPlayer_SetKeyframePolicy(player: ?*b3RecPlayer, budgetBytes: usize, minIntervalFrames: c_int) void;
/// @return the keyframe memory budget in bytes
pub extern fn b3RecPlayer_GetKeyframeBudget(player: ?*const b3RecPlayer) usize;
/// @return the finest keyframe spacing in frames
pub extern fn b3RecPlayer_GetKeyframeMinInterval(player: ?*const b3RecPlayer) c_int;
/// @return the current keyframe spacing in frames; starts at the min interval and doubles as the
/// ring evicts to stay under budget, so it reflects the effective backward-seek granularity now
pub extern fn b3RecPlayer_GetKeyframeInterval(player: ?*const b3RecPlayer) c_int;
/// @return the memory currently held by keyframe snapshots, in bytes
pub extern fn b3RecPlayer_GetKeyframeBytes(player: ?*const b3RecPlayer) usize;
/// @return the number of bodies tracked in creation order (including holes for destroyed bodies)
pub extern fn b3RecPlayer_GetBodyCount(player: ?*const b3RecPlayer) c_int;
/// Resolve a creation ordinal to the live body id at the current frame.
/// @return the body id, or a null id if that ordinal is out of range or its body is destroyed
pub extern fn b3RecPlayer_GetBodyId(player: ?*const b3RecPlayer, index: c_int) b3BodyId;
/// Wire host debug-shape callbacks into the player's replay world so a renderer can build
/// per-shape draw resources (the 3D sample needs this or the replay world draws nothing).
/// Rebuilds the current world under the new callbacks and rewinds to frame 0, so call it
/// once right after b3RecPlayer_Create and re-read the world id afterward. The callbacks
/// persist across Restart and backward seeks, which recreate the world internally.
/// @param player the player to configure
/// @param createDebugShape called when a replayed shape is added; returns a user draw handle
/// @param destroyDebugShape called when a replayed shape is removed; may be NULL
/// @param context user context passed to both callbacks
pub extern fn b3RecPlayer_SetDebugShapeCallbacks(player: ?*b3RecPlayer, createDebugShape: ?*const b3CreateDebugShapeCallback, destroyDebugShape: ?*const b3DestroyDebugShapeCallback, context: ?*anyopaque) void;
/// Draw the spatial queries recorded during the most recently replayed frame, layered on top of the
/// world. Call after b3World_Draw. NULL draw function pointers are skipped.
/// @param player a valid player handle
/// @param draw debug draw callbacks
/// @param queryIndex index of the frame query to draw, or -1 to draw all of them
/// @param selectedIndex index of the query to emphasize (reserved color plus a label), or -1 for none
pub extern fn b3RecPlayer_DrawFrameQueries(player: ?*b3RecPlayer, draw: [*c]b3DebugDraw, queryIndex: c_int, selectedIndex: c_int) void;
pub const b3_recQueryOverlapAABB: c_int = 0;
pub const b3_recQueryOverlapShape: c_int = 1;
pub const b3_recQueryCastRay: c_int = 2;
pub const b3_recQueryCastShape: c_int = 3;
pub const b3_recQueryCastRayClosest: c_int = 4;
pub const b3_recQueryCastMover: c_int = 5;
pub const b3_recQueryCollideMover: c_int = 6;
pub const enum_b3RecQueryType = c_uint;
/// The kind of a recorded spatial query, matching the public query and cast functions.
pub const b3RecQueryType = enum_b3RecQueryType;
pub const struct_b3RecQueryInfo = extern struct {
    type: b3RecQueryType = @import("std").mem.zeroes(b3RecQueryType),
    filter: b3QueryFilter = @import("std").mem.zeroes(b3QueryFilter),
    aabb: b3AABB = @import("std").mem.zeroes(b3AABB),
    origin: b3Pos = @import("std").mem.zeroes(b3Pos),
    translation: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    hitCount: c_int = 0,
    key: u64 = 0,
    id: u64 = 0,
    name: [*c]const u8 = null,
};
/// A spatial query recorded during a replayed frame, exposed for inspection.
pub const b3RecQueryInfo = struct_b3RecQueryInfo;
pub const struct_b3RecQueryHit = extern struct {
    shape: b3ShapeId = @import("std").mem.zeroes(b3ShapeId),
    point: b3Pos = @import("std").mem.zeroes(b3Pos),
    normal: b3Vec3 = @import("std").mem.zeroes(b3Vec3),
    fraction: f32 = 0,
};
/// One result of a recorded spatial query.
pub const b3RecQueryHit = struct_b3RecQueryHit;
/// @return the number of spatial queries recorded for the most recently replayed frame
pub extern fn b3RecPlayer_GetFrameQueryCount(player: ?*const b3RecPlayer) c_int;
/// Get a recorded query from the most recently replayed frame by index.
pub extern fn b3RecPlayer_GetFrameQuery(player: ?*const b3RecPlayer, index: c_int) b3RecQueryInfo;
/// Get one result of a recorded query from the most recently replayed frame.
pub extern fn b3RecPlayer_GetFrameQueryHit(player: ?*const b3RecPlayer, queryIndex: c_int, hitIndex: c_int) b3RecQueryHit;
/// Create a rigid body given a definition. No reference to the definition is retained. So you can create the definition
/// on the stack and pass it as a pointer.
/// @code{.c}
/// b3BodyDef bodyDef = b3DefaultBodyDef();
/// b3BodyId myBodyId = b3CreateBody(myWorldId, &bodyDef);
/// @endcode
/// @warning This function is locked during callbacks.
pub extern fn b3CreateBody(worldId: b3WorldId, def: [*c]const b3BodyDef) b3BodyId;
/// Destroy a rigid body given an id. This destroys all shapes and joints attached to the body.
/// Do not keep references to the associated shapes and joints.
pub extern fn b3DestroyBody(bodyId: b3BodyId) void;
/// Body identifier validation. A valid body exists in a world and is non-null.
/// This can be used to detect orphaned ids. Provides validation for up to 64K allocations.
pub extern fn b3Body_IsValid(id: b3BodyId) bool;
/// Get the body type: static, kinematic, or dynamic
pub extern fn b3Body_GetType(bodyId: b3BodyId) b3BodyType;
/// Change the body type. This is an expensive operation. This automatically updates the mass
/// properties regardless of the automatic mass setting.
pub extern fn b3Body_SetType(bodyId: b3BodyId, @"type": b3BodyType) void;
/// Set the body name.
pub extern fn b3Body_SetName(bodyId: b3BodyId, name: [*c]const u8) void;
/// Get the body name. Returns an empty string if the name isn't set.
pub extern fn b3Body_GetName(bodyId: b3BodyId) [*c]const u8;
/// Set the user data for a body
pub extern fn b3Body_SetUserData(bodyId: b3BodyId, userData: ?*anyopaque) void;
/// Get the user data stored in a body
pub extern fn b3Body_GetUserData(bodyId: b3BodyId) ?*anyopaque;
/// Get the world position of a body. This is the location of the body origin.
pub extern fn b3Body_GetPosition(bodyId: b3BodyId) b3Pos;
/// Get the world rotation of a body as a quaternion
pub extern fn b3Body_GetRotation(bodyId: b3BodyId) b3Quat;
/// Get the world transform of a body.
pub extern fn b3Body_GetTransform(bodyId: b3BodyId) b3WorldTransform;
/// Set the world transform of a body. This acts as a teleport and is fairly expensive.
/// @note Generally you should create a body with the intended transform.
/// @see b3BodyDef::position and b3BodyDef::rotation.
pub extern fn b3Body_SetTransform(bodyId: b3BodyId, position: b3Pos, rotation: b3Quat) void;
/// Get a local point on a body given a world point.
pub extern fn b3Body_GetLocalPoint(bodyId: b3BodyId, worldPoint: b3Pos) b3Vec3;
/// Get a world point on a body given a local point.
pub extern fn b3Body_GetWorldPoint(bodyId: b3BodyId, localPoint: b3Vec3) b3Pos;
/// Get a local vector on a body given a world vector.
pub extern fn b3Body_GetLocalVector(bodyId: b3BodyId, worldVector: b3Vec3) b3Vec3;
/// Get a world vector on a body given a local vector.
pub extern fn b3Body_GetWorldVector(bodyId: b3BodyId, localVector: b3Vec3) b3Vec3;
/// Get the linear velocity of a body's center of mass. Usually in meters per second.
pub extern fn b3Body_GetLinearVelocity(bodyId: b3BodyId) b3Vec3;
/// Get the angular velocity of a body in radians per second.
pub extern fn b3Body_GetAngularVelocity(bodyId: b3BodyId) b3Vec3;
/// Set the linear velocity of a body at the center of mass. Usually in meters per second.
pub extern fn b3Body_SetLinearVelocity(bodyId: b3BodyId, linearVelocity: b3Vec3) void;
/// Set the angular velocity of a body in radians per second.
pub extern fn b3Body_SetAngularVelocity(bodyId: b3BodyId, angularVelocity: b3Vec3) void;
/// Set the velocity to reach the given transform after a given time step.
/// The result will be close but maybe not exact. This is meant for kinematic bodies.
/// The target is not applied if the velocity would be below the sleep threshold.
/// This will optionally wake the body if asleep, but only if the movement is significant.
pub extern fn b3Body_SetTargetTransform(bodyId: b3BodyId, target: b3WorldTransform, timeStep: f32, wake: bool) void;
/// Get the linear velocity of a local point attached to a body. Usually in meters per second.
pub extern fn b3Body_GetLocalPointVelocity(bodyId: b3BodyId, localPoint: b3Vec3) b3Vec3;
/// Get the linear velocity of a world point attached to a body. Usually in meters per second.
pub extern fn b3Body_GetWorldPointVelocity(bodyId: b3BodyId, worldPoint: b3Pos) b3Vec3;
/// Apply a force at a world point. If the force is not applied at the center of mass,
/// it will generate a torque and affect the angular velocity. This optionally wakes up the body.
/// The force is ignored if the body is not awake.
/// @param bodyId The body id
/// @param force The world force vector, usually in newtons (N)
/// @param point The world position of the point of application
/// @param wake Option to wake up the body
pub extern fn b3Body_ApplyForce(bodyId: b3BodyId, force: b3Vec3, point: b3Pos, wake: bool) void;
/// Apply a force to the center of mass. This optionally wakes up the body.
/// The force is ignored if the body is not awake.
/// @param bodyId The body id
/// @param force the world force vector, usually in newtons (N).
/// @param wake also wake up the body
pub extern fn b3Body_ApplyForceToCenter(bodyId: b3BodyId, force: b3Vec3, wake: bool) void;
/// Apply a torque. This affects the angular velocity without affecting the linear velocity.
/// This optionally wakes the body. The torque is ignored if the body is not awake.
/// @param bodyId The body id
/// @param torque the world torque vector, usually in N*m.
/// @param wake also wake up the body
pub extern fn b3Body_ApplyTorque(bodyId: b3BodyId, torque: b3Vec3, wake: bool) void;
/// Apply an impulse at a point. This immediately modifies the velocity.
/// It also modifies the angular velocity if the point of application
/// is not at the center of mass. This optionally wakes the body.
/// The impulse is ignored if the body is not awake.
/// @param bodyId The body id
/// @param impulse the world impulse vector, usually in N*s or kg*m/s.
/// @param point the world position of the point of application.
/// @param wake also wake up the body
/// @warning This should be used for one-shot impulses. If you need a steady force,
/// use a force instead, which will work better with the sub-stepping solver.
pub extern fn b3Body_ApplyLinearImpulse(bodyId: b3BodyId, impulse: b3Vec3, point: b3Pos, wake: bool) void;
/// Apply an impulse to the center of mass. This immediately modifies the velocity.
/// The impulse is ignored if the body is not awake. This optionally wakes the body.
/// @param bodyId The body id
/// @param impulse the world impulse vector, usually in N*s or kg*m/s.
/// @param wake also wake up the body
/// @warning This should be used for one-shot impulses. If you need a steady force,
/// use a force instead, which will work better with the sub-stepping solver.
pub extern fn b3Body_ApplyLinearImpulseToCenter(bodyId: b3BodyId, impulse: b3Vec3, wake: bool) void;
/// Apply an angular impulse in world space. The impulse is ignored if the body is not awake.
/// This optionally wakes the body.
/// @param bodyId The body id
/// @param impulse the world angular impulse vector, usually in units of kg*m*m/s
/// @param wake also wake up the body
/// @warning This should be used for one-shot impulses. If you need a steady torque,
/// use a torque instead, which will work better with the sub-stepping solver.
pub extern fn b3Body_ApplyAngularImpulse(bodyId: b3BodyId, impulse: b3Vec3, wake: bool) void;
/// Get the mass of the body, usually in kilograms
pub extern fn b3Body_GetMass(bodyId: b3BodyId) f32;
/// Get the rotational inertia of the body in local space, usually in kg*m^2
pub extern fn b3Body_GetLocalRotationalInertia(bodyId: b3BodyId) b3Matrix3;
/// Get the inverse mass of the body, usually in 1/kilograms
pub extern fn b3Body_GetInverseMass(bodyId: b3BodyId) f32;
/// Get the inverse rotational inertia of the body in world space, usually in 1/kg*m^2
pub extern fn b3Body_GetWorldInverseRotationalInertia(bodyId: b3BodyId) b3Matrix3;
/// Get the center of mass position of the body in local space
pub extern fn b3Body_GetLocalCenter(bodyId: b3BodyId) b3Vec3;
/// Get the center of mass position of the body in world space
pub extern fn b3Body_GetWorldCenter(bodyId: b3BodyId) b3Pos;
/// Override the body's mass properties. Normally this is computed automatically using the
/// shape geometry and density. This information is lost if a shape is added or removed or if the
/// body type changes.
pub extern fn b3Body_SetMassData(bodyId: b3BodyId, massData: b3MassData) void;
/// Get the mass data for a body
pub extern fn b3Body_GetMassData(bodyId: b3BodyId) b3MassData;
/// This updates the mass properties to the sum of the mass properties of the shapes.
/// This normally does not need to be called unless you called SetMassData to override
/// the mass and you later want to reset the mass.
/// You may also use this when automatic mass computation has been disabled.
/// You should call this regardless of body type.
pub extern fn b3Body_ApplyMassFromShapes(bodyId: b3BodyId) void;
/// Adjust the linear damping. Normally this is set in b3BodyDef before creation.
pub extern fn b3Body_SetLinearDamping(bodyId: b3BodyId, linearDamping: f32) void;
/// Get the current linear damping.
pub extern fn b3Body_GetLinearDamping(bodyId: b3BodyId) f32;
/// Adjust the angular damping. Normally this is set in b3BodyDef before creation.
pub extern fn b3Body_SetAngularDamping(bodyId: b3BodyId, angularDamping: f32) void;
/// Get the current angular damping.
pub extern fn b3Body_GetAngularDamping(bodyId: b3BodyId) f32;
/// Adjust the gravity scale. Normally this is set in b3BodyDef before creation.
/// @see b3BodyDef::gravityScale
pub extern fn b3Body_SetGravityScale(bodyId: b3BodyId, gravityScale: f32) void;
/// Get the current gravity scale
pub extern fn b3Body_GetGravityScale(bodyId: b3BodyId) f32;
/// @return true if this body is awake
pub extern fn b3Body_IsAwake(bodyId: b3BodyId) bool;
/// Wake a body from sleep. This wakes the entire island the body is touching.
/// @warning Putting a body to sleep will put the entire island of bodies touching this body to sleep,
/// which can be expensive and possibly unintuitive.
pub extern fn b3Body_SetAwake(bodyId: b3BodyId, awake: bool) void;
/// Enable or disable sleeping for this body. If sleeping is disabled the body will wake.
pub extern fn b3Body_EnableSleep(bodyId: b3BodyId, enableSleep: bool) void;
/// Returns true if sleeping is enabled for this body
pub extern fn b3Body_IsSleepEnabled(bodyId: b3BodyId) bool;
/// Set the sleep threshold, usually in meters per second
pub extern fn b3Body_SetSleepThreshold(bodyId: b3BodyId, sleepThreshold: f32) void;
/// Get the sleep threshold, usually in meters per second.
pub extern fn b3Body_GetSleepThreshold(bodyId: b3BodyId) f32;
/// Returns true if this body is enabled
pub extern fn b3Body_IsEnabled(bodyId: b3BodyId) bool;
/// Disable a body by removing it completely from the simulation. This is expensive.
pub extern fn b3Body_Disable(bodyId: b3BodyId) void;
/// Enable a body by adding it to the simulation. This is expensive.
pub extern fn b3Body_Enable(bodyId: b3BodyId) void;
/// Set the motion locks on this body.
pub extern fn b3Body_SetMotionLocks(bodyId: b3BodyId, locks: b3MotionLocks) void;
/// Get the motion locks for this body.
pub extern fn b3Body_GetMotionLocks(bodyId: b3BodyId) b3MotionLocks;
/// Set this body to be a bullet. A bullet does continuous collision detection
/// against dynamic bodies (but not other bullets).
pub extern fn b3Body_SetBullet(bodyId: b3BodyId, flag: bool) void;
/// Is this body a bullet?
pub extern fn b3Body_IsBullet(bodyId: b3BodyId) bool;
/// Allow this body to rotate fast. Useful for axially symmetric bodies, such as vehicle wheels.
/// Normally rotation speed is clamped to improve CCD. However, this clamping is unnecessary for
/// bodies that only rotate fast around an axis of symmetry.
pub extern fn b3Body_AllowFastRotation(bodyId: b3BodyId, flag: bool) void;
/// Is this body allowed to rotate fast?
pub extern fn b3Body_IsFastRotationAllowed(bodyId: b3BodyId) bool;
/// Enable or disable contact recycling for this body. Contact recycling is a performance optimization
/// that reuses contact manifolds when bodies move slightly. Disabling it can avoid ghost collisions
/// on characters at the cost of higher per-step work. Existing contacts retain their prior setting;
/// only contacts created after this call see the new value.
/// @see b3BodyDef::enableContactRecycling
pub extern fn b3Body_EnableContactRecycling(bodyId: b3BodyId, flag: bool) void;
/// Is contact recycling enabled on this body?
pub extern fn b3Body_IsContactRecyclingEnabled(bodyId: b3BodyId) bool;
/// Enable/disable hit events on all shapes
/// @see b3ShapeDef::enableHitEvents
pub extern fn b3Body_EnableHitEvents(bodyId: b3BodyId, flag: bool) void;
/// Get the world that owns this body
pub extern fn b3Body_GetWorld(bodyId: b3BodyId) b3WorldId;
/// Get the number of shapes on this body
pub extern fn b3Body_GetShapeCount(bodyId: b3BodyId) c_int;
/// Get the shape ids for all shapes on this body, up to the provided capacity.
/// @returns the number of shape ids stored in the user array
pub extern fn b3Body_GetShapes(bodyId: b3BodyId, shapeArray: [*c]b3ShapeId, capacity: c_int) c_int;
/// Get the number of joints on this body
pub extern fn b3Body_GetJointCount(bodyId: b3BodyId) c_int;
/// Get the joint ids for all joints on this body, up to the provided capacity
/// @returns the number of joint ids stored in the user array
pub extern fn b3Body_GetJoints(bodyId: b3BodyId, jointArray: [*c]b3JointId, capacity: c_int) c_int;
/// Get the maximum capacity required for retrieving all the touching contacts on a body
pub extern fn b3Body_GetContactCapacity(bodyId: b3BodyId) c_int;
/// Get the touching contact data for a body
pub extern fn b3Body_GetContactData(bodyId: b3BodyId, contactData: [*c]b3ContactData, capacity: c_int) c_int;
/// Get the current world AABB that contains all the attached shapes. Note that this may not encompass the body origin.
/// If there are no shapes attached then the returned AABB is empty and centered on the body origin.
pub extern fn b3Body_ComputeAABB(bodyId: b3BodyId) b3AABB;
/// Get the closest point on a body to a world target.
pub extern fn b3Body_GetClosestPoint(bodyId: b3BodyId, result: [*c]b3Vec3, target: b3Vec3) f32;
/// Cast a ray at a specific body using a specified body transform.
pub extern fn b3Body_CastRay(bodyId: b3BodyId, origin: b3Pos, translation: b3Vec3, filter: b3QueryFilter, maxFraction: f32, bodyTransform: b3WorldTransform) b3BodyCastResult;
/// Cast a shape at a specific body using a specified body transform.
pub extern fn b3Body_CastShape(bodyId: b3BodyId, origin: b3Pos, proxy: [*c]const b3ShapeProxy, translation: b3Vec3, filter: b3QueryFilter, maxFraction: f32, canEncroach: bool, bodyTransform: b3WorldTransform) b3BodyCastResult;
/// Overlap a shape with a specific body using a specified body transform.
pub extern fn b3Body_OverlapShape(bodyId: b3BodyId, origin: b3Pos, proxy: [*c]const b3ShapeProxy, filter: b3QueryFilter, bodyTransform: b3WorldTransform) bool;
/// Collide a character mover with a specific body using a specified body transform.
pub extern fn b3Body_CollideMover(bodyId: b3BodyId, bodyPlanes: [*c]b3BodyPlaneResult, planeCapacity: c_int, origin: b3Pos, mover: [*c]const b3Capsule, filter: b3QueryFilter, bodyTransform: b3WorldTransform) c_int;
/// Create a circle shape and attach it to a body. The shape definition and geometry are fully cloned.
/// Contacts are not created until the next time step.
/// @return the shape id for accessing the shape
pub extern fn b3CreateSphereShape(bodyId: b3BodyId, def: [*c]const b3ShapeDef, sphere: [*c]const b3Sphere) b3ShapeId;
/// Create a capsule shape and attach it to a body. The shape definition and geometry are fully cloned.
/// Contacts are not created until the next time step.
/// @return the shape id for accessing the shape
pub extern fn b3CreateCapsuleShape(bodyId: b3BodyId, def: [*c]const b3ShapeDef, capsule: [*c]const b3Capsule) b3ShapeId;
/// Create a convex hull shape and attach it to a body. The shape definition is fully cloned. Contacts are not created
/// until the next time step.
/// @return the shape id for accessing the shape
pub extern fn b3CreateHullShape(bodyId: b3BodyId, def: [*c]const b3ShapeDef, hull: [*c]const b3HullData) b3ShapeId;
/// Create a convex hull shape and attach it to a body. The hull is cloned then transformed with scale applied first.
/// Use this for non-uniform or mirrored scale or a baked local transform. The baked result is shared through the
/// world hull database. The shape definition and geometry are fully cloned. Contacts are not created until the next time step.
/// @return the shape id for accessing the shape
pub extern fn b3CreateTransformedHullShape(bodyId: b3BodyId, def: [*c]const b3ShapeDef, hull: [*c]const b3HullData, transform: b3Transform, scale: b3Vec3) b3ShapeId;
/// Create a mesh hull shape and attach it to a body. The shape definition is fully cloned but the mesh is not.
/// Contacts are not created until the next time step.
/// Mesh collision only creates contacts on static bodies.
/// @warning this holds reference to the input mesh data which must remain valid for the lifetime of this shape
/// @return the shape id for accessing the shape
pub extern fn b3CreateMeshShape(bodyId: b3BodyId, def: [*c]const b3ShapeDef, mesh: [*c]const b3MeshData, scale: b3Vec3) b3ShapeId;
/// Create a height-field shape and attach it to a body. The shape definition is fully cloned but the height field is not.
/// Contacts are not created until the next time step.
/// Height field is only allowed on static bodies.
/// @warning this holds reference to the input height field which must remain valid for the lifetime of this shape
/// @return the shape id for accessing the shape
pub extern fn b3CreateHeightFieldShape(bodyId: b3BodyId, def: [*c]const b3ShapeDef, heightField: [*c]const b3HeightFieldData) b3ShapeId;
/// Baked compound shapes are only allowed on static bodies.
/// Note: runtime compounds are achieved by adding multiple shapes to a body.
/// Runtime compounds can be dynamic and/or kinematic.
pub extern fn b3CreateBakedCompoundShape(bodyId: b3BodyId, def: [*c]b3ShapeDef, compound: [*c]const b3CompoundData) b3ShapeId;
/// Destroy a shape. You may defer the body mass update which can improve performance if several shapes on a
/// body are destroyed at once.
/// @see b3Body_ApplyMassFromShapes
pub extern fn b3DestroyShape(shapeId: b3ShapeId, updateBodyMass: bool) void;
/// Shape identifier validation. Provides validation for up to 64K allocations.
pub extern fn b3Shape_IsValid(id: b3ShapeId) bool;
/// Get the type of a shape
pub extern fn b3Shape_GetType(shapeId: b3ShapeId) b3ShapeType;
/// Get the id of the body that a shape is attached to
pub extern fn b3Shape_GetBody(shapeId: b3ShapeId) b3BodyId;
/// Get the world that owns this shape
pub extern fn b3Shape_GetWorld(shapeId: b3ShapeId) b3WorldId;
/// Returns true if the shape is a sensor
pub extern fn b3Shape_IsSensor(shapeId: b3ShapeId) bool;
/// Set the shape name.
pub extern fn b3Shape_SetName(shapeId: b3ShapeId, name: [*c]const u8) void;
/// Get the shape name. Returns an empty string if the name isn't set.
pub extern fn b3Shape_GetName(shapeId: b3ShapeId) [*c]const u8;
/// Set the user data for a shape
pub extern fn b3Shape_SetUserData(shapeId: b3ShapeId, userData: ?*anyopaque) void;
/// Get the user data for a shape. This is useful when you get a shape id
/// from an event or query.
pub extern fn b3Shape_GetUserData(shapeId: b3ShapeId) ?*anyopaque;
/// Set the mass density of a shape, usually in kg/m^3.
/// This will optionally update the mass properties on the parent body.
/// @see b3ShapeDef::density, b3Body_ApplyMassFromShapes
pub extern fn b3Shape_SetDensity(shapeId: b3ShapeId, density: f32, updateBodyMass: bool) void;
/// Get the density of a shape, usually in kg/m^3
pub extern fn b3Shape_GetDensity(shapeId: b3ShapeId) f32;
/// Set the friction on a shape
pub extern fn b3Shape_SetFriction(shapeId: b3ShapeId, friction: f32) void;
/// Get the friction of a shape
pub extern fn b3Shape_GetFriction(shapeId: b3ShapeId) f32;
/// Set the shape restitution (bounciness)
pub extern fn b3Shape_SetRestitution(shapeId: b3ShapeId, restitution: f32) void;
/// Get the shape restitution
pub extern fn b3Shape_GetRestitution(shapeId: b3ShapeId) f32;
/// Set the shape base surface material. Does not change per triangle materials.
pub extern fn b3Shape_SetSurfaceMaterial(shapeId: b3ShapeId, surfaceMaterial: b3SurfaceMaterial) void;
/// Get the base shape surface material.
pub extern fn b3Shape_GetSurfaceMaterial(shapeId: b3ShapeId) b3SurfaceMaterial;
/// Get the number of mesh surface materials.
pub extern fn b3Shape_GetMeshMaterialCount(shapeId: b3ShapeId) c_int;
/// Set a surface material for a mesh shape.
pub extern fn b3Shape_SetMeshMaterial(shapeId: b3ShapeId, surfaceMaterial: b3SurfaceMaterial, index: c_int) void;
/// Get a surface material for a mesh shape
pub extern fn b3Shape_GetMeshSurfaceMaterial(shapeId: b3ShapeId, index: c_int) b3SurfaceMaterial;
/// Get the shape filter
pub extern fn b3Shape_GetFilter(shapeId: b3ShapeId) b3Filter;
/// Set the current filter. This is almost as expensive as recreating the shape.
/// @see b3ShapeDef::filter
/// @param shapeId the shape
/// @param filter the new filter
/// @param invokeContacts if true then the shape will have all contacts recomputed the next time step (expensive)
pub extern fn b3Shape_SetFilter(shapeId: b3ShapeId, filter: b3Filter, invokeContacts: bool) void;
/// Enable sensor events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors.
/// @see b3ShapeDef::isSensor
pub extern fn b3Shape_EnableSensorEvents(shapeId: b3ShapeId, flag: bool) void;
/// Returns true if sensor events are enabled
pub extern fn b3Shape_AreSensorEventsEnabled(shapeId: b3ShapeId) bool;
/// Enable contact events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors.
/// @see b3ShapeDef::enableContactEvents
pub extern fn b3Shape_EnableContactEvents(shapeId: b3ShapeId, flag: bool) void;
/// Returns true if contact events are enabled
pub extern fn b3Shape_AreContactEventsEnabled(shapeId: b3ShapeId) bool;
/// Enable pre-solve contact events for this shape. Only applies to dynamic bodies. These are expensive
/// and must be carefully handled due to multithreading. Ignored for sensors.
/// @see b3PreSolveFcn
pub extern fn b3Shape_EnablePreSolveEvents(shapeId: b3ShapeId, flag: bool) void;
/// Returns true if pre-solve events are enabled
pub extern fn b3Shape_ArePreSolveEventsEnabled(shapeId: b3ShapeId) bool;
/// Enable contact hit events for this shape. Ignored for sensors.
/// @see b3WorldDef.hitEventThreshold
pub extern fn b3Shape_EnableHitEvents(shapeId: b3ShapeId, flag: bool) void;
/// Returns true if hit events are enabled
pub extern fn b3Shape_AreHitEventsEnabled(shapeId: b3ShapeId) bool;
/// Ray cast a shape directly. The ray runs from origin to origin + translation and the hit point
/// comes back as a world position, so the cast stays precise far from the world origin.
pub extern fn b3Shape_RayCast(shapeId: b3ShapeId, origin: b3Pos, translation: b3Vec3) b3WorldCastOutput;
/// Get a copy of the shape's sphere. Asserts the type is correct.
pub extern fn b3Shape_GetSphere(shapeId: b3ShapeId) b3Sphere;
/// Get a copy of the shape's capsule. Asserts the type is correct.
pub extern fn b3Shape_GetCapsule(shapeId: b3ShapeId) b3Capsule;
/// Get the shape's convex hull. Asserts the type is correct.
pub extern fn b3Shape_GetHull(shapeId: b3ShapeId) [*c]const b3HullData;
/// Get the shape's mesh. Asserts the type is correct.
pub extern fn b3Shape_GetMesh(shapeId: b3ShapeId) b3Mesh;
/// Get the shape's height field. Asserts the type is correct.
pub extern fn b3Shape_GetHeightField(shapeId: b3ShapeId) [*c]const b3HeightFieldData;
/// Allows you to change a shape to be a sphere or update the current sphere.
/// This does not modify the mass properties.
/// @see b3Body_ApplyMassFromShapes
pub extern fn b3Shape_SetSphere(shapeId: b3ShapeId, sphere: [*c]const b3Sphere) void;
/// Allows you to change a shape to be a capsule or update the current capsule.
/// This does not modify the mass properties.
/// @see b3Body_ApplyMassFromShapes
pub extern fn b3Shape_SetCapsule(shapeId: b3ShapeId, capsule: [*c]const b3Capsule) void;
/// Allows you to change a shape to be a hull or update the current hull.
/// This does not modify the mass properties.
/// @see b3Body_ApplyMassFromShapes
pub extern fn b3Shape_SetHull(shapeId: b3ShapeId, hull: [*c]const b3HullData) void;
/// Allows you to change a shape to be a mesh or update the current mesh.
/// This does not modify the mass properties.
/// @see b3Body_ApplyMassFromShapes
pub extern fn b3Shape_SetMesh(shapeId: b3ShapeId, meshData: [*c]const b3MeshData, scale: b3Vec3) void;
/// Get the maximum capacity required for retrieving all the touching contacts on a shape
pub extern fn b3Shape_GetContactCapacity(shapeId: b3ShapeId) c_int;
/// Get the touching contact data for a shape. The provided shapeId will be either shapeIdA or shapeIdB on the contact data.
/// @note Box3D uses speculative collision so some contact points may be separated.
/// @returns the number of elements filled in the provided array
/// @warning do not ignore the return value, it specifies the valid number of elements
pub extern fn b3Shape_GetContactData(shapeId: b3ShapeId, contactData: [*c]b3ContactData, capacity: c_int) c_int;
/// Get the maximum capacity required for retrieving all the overlapped shapes on a sensor shape.
/// This returns 0 if the provided shape is not a sensor.
/// @param shapeId the id of a sensor shape
/// @returns the required capacity to get all the overlaps in b3Shape_GetSensorOverlaps
pub extern fn b3Shape_GetSensorCapacity(shapeId: b3ShapeId) c_int;
/// Get the overlap data for a sensor shape.
/// @param shapeId the id of a sensor shape
/// @param visitorIds a user allocated array that is filled with the overlapping shapes (visitors)
/// @param capacity the capacity of overlappedShapes
/// @returns the number of elements filled in the provided array
/// @warning do not ignore the return value, it specifies the valid number of elements
/// @warning overlaps may contain destroyed shapes so use b3Shape_IsValid to confirm each overlap
pub extern fn b3Shape_GetSensorData(shapeId: b3ShapeId, visitorIds: [*c]b3ShapeId, capacity: c_int) c_int;
/// Get the current world AABB
pub extern fn b3Shape_GetAABB(shapeId: b3ShapeId) b3AABB;
/// Compute the mass data for a shape
pub extern fn b3Shape_ComputeMassData(shapeId: b3ShapeId) b3MassData;
/// Get the closest point on a shape to a target point. Target and result are in world space.
pub extern fn b3Shape_GetClosestPoint(shapeId: b3ShapeId, target: b3Vec3) b3Vec3;
/// Apply a wind force to the body for this shape using the density of air. This considers
/// the projected area of the shape in the wind direction. This also considers
/// the relative velocity of the shape.
/// @param shapeId the shape id
/// @param wind the wind velocity in world space
/// @param drag the drag coefficient, the force that opposes the relative velocity
/// @param lift the lift coefficient, the force that is perpendicular to the relative velocity
/// @param maxSpeed the maximum relative speed. Speed cap is necessary for stability. Typically 10m/s or less.
/// @param wake should this wake the body
pub extern fn b3Shape_ApplyWind(shapeId: b3ShapeId, wind: b3Vec3, drag: f32, lift: f32, maxSpeed: f32, wake: bool) void;
/// Destroy a joint
pub extern fn b3DestroyJoint(jointId: b3JointId, wakeAttached: bool) void;
/// Joint identifier validation. Provides validation for up to 64K allocations.
pub extern fn b3Joint_IsValid(id: b3JointId) bool;
/// Get the joint type
pub extern fn b3Joint_GetType(jointId: b3JointId) b3JointType;
/// Get body A id on a joint
pub extern fn b3Joint_GetBodyA(jointId: b3JointId) b3BodyId;
/// Get body B id on a joint
pub extern fn b3Joint_GetBodyB(jointId: b3JointId) b3BodyId;
/// Get the world that owns this joint
pub extern fn b3Joint_GetWorld(jointId: b3JointId) b3WorldId;
/// Set the local frame on bodyA
pub extern fn b3Joint_SetLocalFrameA(jointId: b3JointId, localFrame: b3Transform) void;
/// Get the local frame on bodyA
pub extern fn b3Joint_GetLocalFrameA(jointId: b3JointId) b3Transform;
/// Set the local frame on bodyB
pub extern fn b3Joint_SetLocalFrameB(jointId: b3JointId, localFrame: b3Transform) void;
/// Get the local frame on bodyB
pub extern fn b3Joint_GetLocalFrameB(jointId: b3JointId) b3Transform;
/// Toggle collision between connected bodies
pub extern fn b3Joint_SetCollideConnected(jointId: b3JointId, shouldCollide: bool) void;
/// Is collision allowed between connected bodies?
pub extern fn b3Joint_GetCollideConnected(jointId: b3JointId) bool;
/// Set the user data on a joint
pub extern fn b3Joint_SetUserData(jointId: b3JointId, userData: ?*anyopaque) void;
/// Get the user data on a joint
pub extern fn b3Joint_GetUserData(jointId: b3JointId) ?*anyopaque;
/// Wake the bodies connect to this joint
pub extern fn b3Joint_WakeBodies(jointId: b3JointId) void;
/// Get the current constraint force for this joint
pub extern fn b3Joint_GetConstraintForce(jointId: b3JointId) b3Vec3;
/// Get the current constraint torque for this joint
pub extern fn b3Joint_GetConstraintTorque(jointId: b3JointId) b3Vec3;
/// Get the current linear separation error for this joint. Does not consider admissible movement. Usually in meters.
pub extern fn b3Joint_GetLinearSeparation(jointId: b3JointId) f32;
/// Get the current angular separation error for this joint. Does not consider admissible movement. Usually in radians.
pub extern fn b3Joint_GetAngularSeparation(jointId: b3JointId) f32;
/// Set the joint constraint tuning. Advanced feature.
/// @param jointId the joint
/// @param hertz the stiffness in Hertz (cycles per second)
/// @param dampingRatio the non-dimensional damping ratio (one for critical damping)
pub extern fn b3Joint_SetConstraintTuning(jointId: b3JointId, hertz: f32, dampingRatio: f32) void;
/// Get the joint constraint tuning. Advanced feature.
pub extern fn b3Joint_GetConstraintTuning(jointId: b3JointId, hertz: [*c]f32, dampingRatio: [*c]f32) void;
/// Set the force threshold for joint events (Newtons)
pub extern fn b3Joint_SetForceThreshold(jointId: b3JointId, threshold: f32) void;
/// Get the force threshold for joint events (Newtons)
pub extern fn b3Joint_GetForceThreshold(jointId: b3JointId) f32;
/// Set the torque threshold for joint events (N-m)
pub extern fn b3Joint_SetTorqueThreshold(jointId: b3JointId, threshold: f32) void;
/// Get the torque threshold for joint events (N-m)
pub extern fn b3Joint_GetTorqueThreshold(jointId: b3JointId) f32;
/// Create a parallel joint
/// @see b3ParallelJointDef for details
pub extern fn b3CreateParallelJoint(worldId: b3WorldId, def: [*c]const b3ParallelJointDef) b3JointId;
/// Set the spring stiffness in Hertz
pub extern fn b3ParallelJoint_SetSpringHertz(jointId: b3JointId, hertz: f32) void;
/// Set the spring damping ratio, non-dimensional
pub extern fn b3ParallelJoint_SetSpringDampingRatio(jointId: b3JointId, dampingRatio: f32) void;
/// Get the spring Hertz
pub extern fn b3ParallelJoint_GetSpringHertz(jointId: b3JointId) f32;
/// Get the spring damping ratio
pub extern fn b3ParallelJoint_GetSpringDampingRatio(jointId: b3JointId) f32;
/// Set the maximum spring torque, usually in newton-meters
pub extern fn b3ParallelJoint_SetMaxTorque(jointId: b3JointId, force: f32) void;
/// Get the maximum spring torque, usually in newton-meters
pub extern fn b3ParallelJoint_GetMaxTorque(jointId: b3JointId) f32;
/// Create a distance joint
/// @see b3DistanceJointDef for details
pub extern fn b3CreateDistanceJoint(worldId: b3WorldId, def: [*c]const b3DistanceJointDef) b3JointId;
/// Set the rest length of a distance joint
/// @param jointId The id for a distance joint
/// @param length The new distance joint length
pub extern fn b3DistanceJoint_SetLength(jointId: b3JointId, length: f32) void;
/// Get the rest length of a distance joint
pub extern fn b3DistanceJoint_GetLength(jointId: b3JointId) f32;
/// Enable/disable the distance joint spring. When disabled the distance joint is rigid.
pub extern fn b3DistanceJoint_EnableSpring(jointId: b3JointId, enableSpring: bool) void;
/// Is the distance joint spring enabled?
pub extern fn b3DistanceJoint_IsSpringEnabled(jointId: b3JointId) bool;
/// Set the force range for the spring.
pub extern fn b3DistanceJoint_SetSpringForceRange(jointId: b3JointId, lowerForce: f32, upperForce: f32) void;
/// Get the force range for the spring.
pub extern fn b3DistanceJoint_GetSpringForceRange(jointId: b3JointId, lowerForce: [*c]f32, upperForce: [*c]f32) void;
/// Set the spring stiffness in Hertz
pub extern fn b3DistanceJoint_SetSpringHertz(jointId: b3JointId, hertz: f32) void;
/// Set the spring damping ratio, non-dimensional
pub extern fn b3DistanceJoint_SetSpringDampingRatio(jointId: b3JointId, dampingRatio: f32) void;
/// Get the spring Hertz
pub extern fn b3DistanceJoint_GetSpringHertz(jointId: b3JointId) f32;
/// Get the spring damping ratio
pub extern fn b3DistanceJoint_GetSpringDampingRatio(jointId: b3JointId) f32;
/// Enable joint limit. The limit only works if the joint spring is enabled. Otherwise the joint is rigid
/// and the limit has no effect.
pub extern fn b3DistanceJoint_EnableLimit(jointId: b3JointId, enableLimit: bool) void;
/// Is the distance joint limit enabled?
pub extern fn b3DistanceJoint_IsLimitEnabled(jointId: b3JointId) bool;
/// Set the minimum and maximum length parameters of a distance joint
pub extern fn b3DistanceJoint_SetLengthRange(jointId: b3JointId, minLength: f32, maxLength: f32) void;
/// Get the distance joint minimum length
pub extern fn b3DistanceJoint_GetMinLength(jointId: b3JointId) f32;
/// Get the distance joint maximum length
pub extern fn b3DistanceJoint_GetMaxLength(jointId: b3JointId) f32;
/// Get the current length of a distance joint
pub extern fn b3DistanceJoint_GetCurrentLength(jointId: b3JointId) f32;
/// Enable/disable the distance joint motor
pub extern fn b3DistanceJoint_EnableMotor(jointId: b3JointId, enableMotor: bool) void;
/// Is the distance joint motor enabled?
pub extern fn b3DistanceJoint_IsMotorEnabled(jointId: b3JointId) bool;
/// Set the distance joint motor speed, usually in meters per second
pub extern fn b3DistanceJoint_SetMotorSpeed(jointId: b3JointId, motorSpeed: f32) void;
/// Get the distance joint motor speed, usually in meters per second
pub extern fn b3DistanceJoint_GetMotorSpeed(jointId: b3JointId) f32;
/// Set the distance joint maximum motor force, usually in newtons
pub extern fn b3DistanceJoint_SetMaxMotorForce(jointId: b3JointId, force: f32) void;
/// Get the distance joint maximum motor force, usually in newtons
pub extern fn b3DistanceJoint_GetMaxMotorForce(jointId: b3JointId) f32;
/// Get the distance joint current motor force, usually in newtons
pub extern fn b3DistanceJoint_GetMotorForce(jointId: b3JointId) f32;
/// Create a motor joint
/// @see b3MotorJointDef for details
pub extern fn b3CreateMotorJoint(worldId: b3WorldId, def: [*c]const b3MotorJointDef) b3JointId;
/// Set the desired relative linear velocity in meters per second
pub extern fn b3MotorJoint_SetLinearVelocity(jointId: b3JointId, velocity: b3Vec3) void;
/// Get the desired relative linear velocity in meters per second
pub extern fn b3MotorJoint_GetLinearVelocity(jointId: b3JointId) b3Vec3;
/// Set the desired relative angular velocity in radians per second
pub extern fn b3MotorJoint_SetAngularVelocity(jointId: b3JointId, velocity: b3Vec3) void;
/// Get the desired relative angular velocity in radians per second
pub extern fn b3MotorJoint_GetAngularVelocity(jointId: b3JointId) b3Vec3;
/// Set the motor joint maximum force, usually in newtons
pub extern fn b3MotorJoint_SetMaxVelocityForce(jointId: b3JointId, maxForce: f32) void;
/// Get the motor joint maximum force, usually in newtons
pub extern fn b3MotorJoint_GetMaxVelocityForce(jointId: b3JointId) f32;
/// Set the motor joint maximum torque, usually in newton-meters
pub extern fn b3MotorJoint_SetMaxVelocityTorque(jointId: b3JointId, maxTorque: f32) void;
/// Get the motor joint maximum torque, usually in newton-meters
pub extern fn b3MotorJoint_GetMaxVelocityTorque(jointId: b3JointId) f32;
/// Set the spring linear hertz stiffness
pub extern fn b3MotorJoint_SetLinearHertz(jointId: b3JointId, hertz: f32) void;
/// Get the spring linear hertz stiffness
pub extern fn b3MotorJoint_GetLinearHertz(jointId: b3JointId) f32;
/// Set the spring linear damping ratio. Use 1.0 for critical damping.
pub extern fn b3MotorJoint_SetLinearDampingRatio(jointId: b3JointId, damping: f32) void;
/// Get the spring linear damping ratio.
pub extern fn b3MotorJoint_GetLinearDampingRatio(jointId: b3JointId) f32;
/// Set the spring angular hertz stiffness
pub extern fn b3MotorJoint_SetAngularHertz(jointId: b3JointId, hertz: f32) void;
/// Get the spring angular hertz stiffness
pub extern fn b3MotorJoint_GetAngularHertz(jointId: b3JointId) f32;
/// Set the spring angular damping ratio. Use 1.0 for critical damping.
pub extern fn b3MotorJoint_SetAngularDampingRatio(jointId: b3JointId, damping: f32) void;
/// Get the spring angular damping ratio.
pub extern fn b3MotorJoint_GetAngularDampingRatio(jointId: b3JointId) f32;
/// Set the maximum spring force in newtons.
pub extern fn b3MotorJoint_SetMaxSpringForce(jointId: b3JointId, maxForce: f32) void;
/// Get the maximum spring force in newtons.
pub extern fn b3MotorJoint_GetMaxSpringForce(jointId: b3JointId) f32;
/// Set the maximum spring torque in newtons * meters
pub extern fn b3MotorJoint_SetMaxSpringTorque(jointId: b3JointId, maxTorque: f32) void;
/// Get the maximum spring torque in newtons * meters
pub extern fn b3MotorJoint_GetMaxSpringTorque(jointId: b3JointId) f32;
/// Create a filter joint.
/// @see b3FilterJointDef for details
pub extern fn b3CreateFilterJoint(worldId: b3WorldId, def: [*c]const b3FilterJointDef) b3JointId;
/// Create a prismatic (slider) joint.
/// @see b3PrismaticJointDef for details
pub extern fn b3CreatePrismaticJoint(worldId: b3WorldId, def: [*c]const b3PrismaticJointDef) b3JointId;
/// Enable/disable the joint spring.
pub extern fn b3PrismaticJoint_EnableSpring(jointId: b3JointId, enableSpring: bool) void;
/// Is the prismatic joint spring enabled or not?
pub extern fn b3PrismaticJoint_IsSpringEnabled(jointId: b3JointId) bool;
/// Set the prismatic joint stiffness in Hertz.
/// This should usually be less than a quarter of the simulation rate. For example, if the simulation
/// runs at 60Hz then the joint stiffness should be 15Hz or less.
pub extern fn b3PrismaticJoint_SetSpringHertz(jointId: b3JointId, hertz: f32) void;
/// Get the prismatic joint stiffness in Hertz
pub extern fn b3PrismaticJoint_GetSpringHertz(jointId: b3JointId) f32;
/// Set the prismatic joint damping ratio (non-dimensional)
pub extern fn b3PrismaticJoint_SetSpringDampingRatio(jointId: b3JointId, dampingRatio: f32) void;
/// Get the prismatic spring damping ratio (non-dimensional)
pub extern fn b3PrismaticJoint_GetSpringDampingRatio(jointId: b3JointId) f32;
/// Set the prismatic joint target translation. Usually in meters.
pub extern fn b3PrismaticJoint_SetTargetTranslation(jointId: b3JointId, targetTranslation: f32) void;
/// Get the prismatic joint target translation. Usually in meters.
pub extern fn b3PrismaticJoint_GetTargetTranslation(jointId: b3JointId) f32;
/// Enable/disable a prismatic joint limit
pub extern fn b3PrismaticJoint_EnableLimit(jointId: b3JointId, enableLimit: bool) void;
/// Is the prismatic joint limit enabled?
pub extern fn b3PrismaticJoint_IsLimitEnabled(jointId: b3JointId) bool;
/// Get the prismatic joint lower limit
pub extern fn b3PrismaticJoint_GetLowerLimit(jointId: b3JointId) f32;
/// Get the prismatic joint upper limit
pub extern fn b3PrismaticJoint_GetUpperLimit(jointId: b3JointId) f32;
/// Set the prismatic joint limits
pub extern fn b3PrismaticJoint_SetLimits(jointId: b3JointId, lower: f32, upper: f32) void;
/// Enable/disable a prismatic joint motor
pub extern fn b3PrismaticJoint_EnableMotor(jointId: b3JointId, enableMotor: bool) void;
/// Is the prismatic joint motor enabled?
pub extern fn b3PrismaticJoint_IsMotorEnabled(jointId: b3JointId) bool;
/// Set the prismatic joint motor speed, usually in meters per second
pub extern fn b3PrismaticJoint_SetMotorSpeed(jointId: b3JointId, motorSpeed: f32) void;
/// Get the prismatic joint motor speed, usually in meters per second
pub extern fn b3PrismaticJoint_GetMotorSpeed(jointId: b3JointId) f32;
/// Set the prismatic joint maximum motor force, usually in newtons
pub extern fn b3PrismaticJoint_SetMaxMotorForce(jointId: b3JointId, force: f32) void;
/// Get the prismatic joint maximum motor force, usually in newtons
pub extern fn b3PrismaticJoint_GetMaxMotorForce(jointId: b3JointId) f32;
/// Get the prismatic joint current motor force, usually in newtons
pub extern fn b3PrismaticJoint_GetMotorForce(jointId: b3JointId) f32;
/// Get the current joint translation, usually in meters.
pub extern fn b3PrismaticJoint_GetTranslation(jointId: b3JointId) f32;
/// Get the current joint translation speed, usually in meters per second.
pub extern fn b3PrismaticJoint_GetSpeed(jointId: b3JointId) f32;
/// Create a revolute joint
/// @see b3RevoluteJointDef for details
pub extern fn b3CreateRevoluteJoint(worldId: b3WorldId, def: [*c]const b3RevoluteJointDef) b3JointId;
/// Enable/disable the revolute joint spring
pub extern fn b3RevoluteJoint_EnableSpring(jointId: b3JointId, enableSpring: bool) void;
/// Is the revolute angular spring enabled?
pub extern fn b3RevoluteJoint_IsSpringEnabled(jointId: b3JointId) bool;
/// Set the revolute joint spring stiffness in Hertz
pub extern fn b3RevoluteJoint_SetSpringHertz(jointId: b3JointId, hertz: f32) void;
/// Get the revolute joint spring stiffness in Hertz
pub extern fn b3RevoluteJoint_GetSpringHertz(jointId: b3JointId) f32;
/// Set the revolute joint spring damping ratio, non-dimensional
pub extern fn b3RevoluteJoint_SetSpringDampingRatio(jointId: b3JointId, dampingRatio: f32) void;
/// Get the revolute joint spring damping ratio, non-dimensional
pub extern fn b3RevoluteJoint_GetSpringDampingRatio(jointId: b3JointId) f32;
/// Set the revolute joint target angle in radians
pub extern fn b3RevoluteJoint_SetTargetAngle(jointId: b3JointId, targetRadians: f32) void;
/// Get the revolute joint target angle in radians
pub extern fn b3RevoluteJoint_GetTargetAngle(jointId: b3JointId) f32;
/// Get the revolute joint current angle in radians relative to the reference angle
/// @see b3RevoluteJointDef::referenceAngle
pub extern fn b3RevoluteJoint_GetAngle(jointId: b3JointId) f32;
/// Enable/disable the revolute joint limit
pub extern fn b3RevoluteJoint_EnableLimit(jointId: b3JointId, enableLimit: bool) void;
/// Is the revolute joint limit enabled?
pub extern fn b3RevoluteJoint_IsLimitEnabled(jointId: b3JointId) bool;
/// Get the revolute joint lower limit in radians
pub extern fn b3RevoluteJoint_GetLowerLimit(jointId: b3JointId) f32;
/// Get the revolute joint upper limit in radians
pub extern fn b3RevoluteJoint_GetUpperLimit(jointId: b3JointId) f32;
/// Set the revolute joint limits in radians
pub extern fn b3RevoluteJoint_SetLimits(jointId: b3JointId, lowerLimitRadians: f32, upperLimitRadians: f32) void;
/// Enable/disable a revolute joint motor
pub extern fn b3RevoluteJoint_EnableMotor(jointId: b3JointId, enableMotor: bool) void;
/// Is the revolute joint motor enabled?
pub extern fn b3RevoluteJoint_IsMotorEnabled(jointId: b3JointId) bool;
/// Set the revolute joint motor speed in radians per second
pub extern fn b3RevoluteJoint_SetMotorSpeed(jointId: b3JointId, motorSpeed: f32) void;
/// Get the revolute joint motor speed in radians per second
pub extern fn b3RevoluteJoint_GetMotorSpeed(jointId: b3JointId) f32;
/// Get the revolute joint current motor torque, usually in newton-meters
pub extern fn b3RevoluteJoint_GetMotorTorque(jointId: b3JointId) f32;
/// Set the revolute joint maximum motor torque, usually in newton-meters
pub extern fn b3RevoluteJoint_SetMaxMotorTorque(jointId: b3JointId, torque: f32) void;
/// Get the revolute joint maximum motor torque, usually in newton-meters
pub extern fn b3RevoluteJoint_GetMaxMotorTorque(jointId: b3JointId) f32;
/// Create a spherical joint
/// @see b3SphericalJointDef for details
pub extern fn b3CreateSphericalJoint(worldId: b3WorldId, def: [*c]const b3SphericalJointDef) b3JointId;
/// Enable/disable the spherical joint cone limit
pub extern fn b3SphericalJoint_EnableConeLimit(jointId: b3JointId, enableLimit: bool) void;
/// Is the spherical joint cone limit enabled?
pub extern fn b3SphericalJoint_IsConeLimitEnabled(jointId: b3JointId) bool;
/// Get the spherical joint cone limit in radians
pub extern fn b3SphericalJoint_GetConeLimit(jointId: b3JointId) f32;
/// Set the spherical joint limits in radians
pub extern fn b3SphericalJoint_SetConeLimit(jointId: b3JointId, angleRadians: f32) void;
/// Get the spherical joint current cone angle in radians.
pub extern fn b3SphericalJoint_GetConeAngle(jointId: b3JointId) f32;
/// Enable/disable the spherical joint limit
pub extern fn b3SphericalJoint_EnableTwistLimit(jointId: b3JointId, enableLimit: bool) void;
/// Is the spherical joint limit enabled?
pub extern fn b3SphericalJoint_IsTwistLimitEnabled(jointId: b3JointId) bool;
/// Get the spherical joint lower limit in radians
pub extern fn b3SphericalJoint_GetLowerTwistLimit(jointId: b3JointId) f32;
/// Get the spherical joint upper limit in radians
pub extern fn b3SphericalJoint_GetUpperTwistLimit(jointId: b3JointId) f32;
/// Set the spherical joint limits in radians
pub extern fn b3SphericalJoint_SetTwistLimits(jointId: b3JointId, lowerLimitRadians: f32, upperLimitRadians: f32) void;
/// Get the spherical joint current twist angle in radians.
pub extern fn b3SphericalJoint_GetTwistAngle(jointId: b3JointId) f32;
/// Enable/disable the spherical joint spring
pub extern fn b3SphericalJoint_EnableSpring(jointId: b3JointId, enableSpring: bool) void;
/// Is the spherical angular spring enabled?
pub extern fn b3SphericalJoint_IsSpringEnabled(jointId: b3JointId) bool;
/// Set the spherical joint spring stiffness in Hertz
pub extern fn b3SphericalJoint_SetSpringHertz(jointId: b3JointId, hertz: f32) void;
/// Get the spherical joint spring stiffness in Hertz
pub extern fn b3SphericalJoint_GetSpringHertz(jointId: b3JointId) f32;
/// Set the spherical joint spring damping ratio, non-dimensional
pub extern fn b3SphericalJoint_SetSpringDampingRatio(jointId: b3JointId, dampingRatio: f32) void;
/// Get the spherical joint spring damping ratio, non-dimensional
pub extern fn b3SphericalJoint_GetSpringDampingRatio(jointId: b3JointId) f32;
/// Set the spherical joint spring target rotation
pub extern fn b3SphericalJoint_SetTargetRotation(jointId: b3JointId, targetRotation: b3Quat) void;
/// Get the spherical joint spring target rotation
pub extern fn b3SphericalJoint_GetTargetRotation(jointId: b3JointId) b3Quat;
/// Enable/disable a spherical joint motor
pub extern fn b3SphericalJoint_EnableMotor(jointId: b3JointId, enableMotor: bool) void;
/// Is the spherical joint motor enabled?
pub extern fn b3SphericalJoint_IsMotorEnabled(jointId: b3JointId) bool;
/// Set the spherical joint motor velocity in radians per second
pub extern fn b3SphericalJoint_SetMotorVelocity(jointId: b3JointId, motorVelocity: b3Vec3) void;
/// Get the spherical joint motor velocity in radians per second
pub extern fn b3SphericalJoint_GetMotorVelocity(jointId: b3JointId) b3Vec3;
/// Get the spherical joint current motor torque, usually in newton-meters
pub extern fn b3SphericalJoint_GetMotorTorque(jointId: b3JointId) b3Vec3;
/// Set the spherical joint maximum motor torque, usually in newton-meters
pub extern fn b3SphericalJoint_SetMaxMotorTorque(jointId: b3JointId, torque: f32) void;
/// Get the spherical joint maximum motor torque, usually in newton-meters
pub extern fn b3SphericalJoint_GetMaxMotorTorque(jointId: b3JointId) f32;
/// Create a weld joint
/// @see b3WeldJointDef for details
pub extern fn b3CreateWeldJoint(worldId: b3WorldId, def: [*c]const b3WeldJointDef) b3JointId;
/// Set the weld joint linear stiffness in Hertz. 0 is rigid.
pub extern fn b3WeldJoint_SetLinearHertz(jointId: b3JointId, hertz: f32) void;
/// Get the weld joint linear stiffness in Hertz
pub extern fn b3WeldJoint_GetLinearHertz(jointId: b3JointId) f32;
/// Set the weld joint linear damping ratio (non-dimensional)
pub extern fn b3WeldJoint_SetLinearDampingRatio(jointId: b3JointId, dampingRatio: f32) void;
/// Get the weld joint linear damping ratio (non-dimensional)
pub extern fn b3WeldJoint_GetLinearDampingRatio(jointId: b3JointId) f32;
/// Set the weld joint angular stiffness in Hertz. 0 is rigid.
pub extern fn b3WeldJoint_SetAngularHertz(jointId: b3JointId, hertz: f32) void;
/// Get the weld joint angular stiffness in Hertz
pub extern fn b3WeldJoint_GetAngularHertz(jointId: b3JointId) f32;
/// Set weld joint angular damping ratio, non-dimensional
pub extern fn b3WeldJoint_SetAngularDampingRatio(jointId: b3JointId, dampingRatio: f32) void;
/// Get the weld joint angular damping ratio, non-dimensional
pub extern fn b3WeldJoint_GetAngularDampingRatio(jointId: b3JointId) f32;
/// Create a wheel joint.
/// @see b3WheelJointDef for details.
pub extern fn b3CreateWheelJoint(worldId: b3WorldId, def: [*c]const b3WheelJointDef) b3JointId;
/// Enable/disable the wheel joint spring.
pub extern fn b3WheelJoint_EnableSuspension(jointId: b3JointId, flag: bool) void;
/// Is the wheel joint spring enabled?
pub extern fn b3WheelJoint_IsSuspensionEnabled(jointId: b3JointId) bool;
/// Set the wheel joint stiffness in Hertz.
pub extern fn b3WheelJoint_SetSuspensionHertz(jointId: b3JointId, hertz: f32) void;
/// Get the wheel joint stiffness in Hertz.
pub extern fn b3WheelJoint_GetSuspensionHertz(jointId: b3JointId) f32;
/// Set the wheel joint damping ratio, non-dimensional.
pub extern fn b3WheelJoint_SetSuspensionDampingRatio(jointId: b3JointId, dampingRatio: f32) void;
/// Get the wheel joint damping ratio, non-dimensional.
pub extern fn b3WheelJoint_GetSuspensionDampingRatio(jointId: b3JointId) f32;
/// Enable/disable the wheel joint limit.
pub extern fn b3WheelJoint_EnableSuspensionLimit(jointId: b3JointId, flag: bool) void;
/// Is the wheel joint limit enabled?
pub extern fn b3WheelJoint_IsSuspensionLimitEnabled(jointId: b3JointId) bool;
/// Get the wheel joint lower limit.
pub extern fn b3WheelJoint_GetLowerSuspensionLimit(jointId: b3JointId) f32;
/// Get the wheel joint upper limit.
pub extern fn b3WheelJoint_GetUpperSuspensionLimit(jointId: b3JointId) f32;
/// Set the wheel joint limits.
pub extern fn b3WheelJoint_SetSuspensionLimits(jointId: b3JointId, lower: f32, upper: f32) void;
/// Enable/disable the wheel joint motor.
pub extern fn b3WheelJoint_EnableSpinMotor(jointId: b3JointId, flag: bool) void;
/// Is the wheel joint motor enabled?
pub extern fn b3WheelJoint_IsSpinMotorEnabled(jointId: b3JointId) bool;
/// Set the wheel joint motor speed in radians per second.
pub extern fn b3WheelJoint_SetSpinMotorSpeed(jointId: b3JointId, speed: f32) void;
/// Get the wheel joint motor speed in radians per second.
pub extern fn b3WheelJoint_GetSpinMotorSpeed(jointId: b3JointId) f32;
/// Set the wheel joint maximum motor torque, usually in newton-meters.
pub extern fn b3WheelJoint_SetMaxSpinTorque(jointId: b3JointId, torque: f32) void;
/// Get the wheel joint maximum motor torque, usually in newton-meters.
pub extern fn b3WheelJoint_GetMaxSpinTorque(jointId: b3JointId) f32;
/// Get the current spin speed in radians per second.
pub extern fn b3WheelJoint_GetSpinSpeed(jointId: b3JointId) f32;
/// Get the wheel joint current motor torque, usually in newton-meters.
pub extern fn b3WheelJoint_GetSpinTorque(jointId: b3JointId) f32;
/// Enable/disable wheel steering. Steering allows the wheel to rotate about the suspension axis.
pub extern fn b3WheelJoint_EnableSteering(jointId: b3JointId, flag: bool) void;
/// Can the wheel steer?
pub extern fn b3WheelJoint_IsSteeringEnabled(jointId: b3JointId) bool;
/// Set the wheel joint steering stiffness in Hertz.
pub extern fn b3WheelJoint_SetSteeringHertz(jointId: b3JointId, hertz: f32) void;
/// Get the wheel joint steering stiffness in Hertz.
pub extern fn b3WheelJoint_GetSteeringHertz(jointId: b3JointId) f32;
/// Set the wheel joint steering damping ratio, non-dimensional.
pub extern fn b3WheelJoint_SetSteeringDampingRatio(jointId: b3JointId, dampingRatio: f32) void;
/// Get the wheel joint steering damping ratio, non-dimensional.
pub extern fn b3WheelJoint_GetSteeringDampingRatio(jointId: b3JointId) f32;
/// Set the wheel joint maximum steering torque in N*m.
pub extern fn b3WheelJoint_SetMaxSteeringTorque(jointId: b3JointId, torque: f32) void;
/// Get the wheel joint maximum steering torque in N*m.
pub extern fn b3WheelJoint_GetMaxSteeringTorque(jointId: b3JointId) f32;
/// Enable/disable the wheel joint steering limit.
pub extern fn b3WheelJoint_EnableSteeringLimit(jointId: b3JointId, flag: bool) void;
/// Is the wheel joint steering limit enabled?
pub extern fn b3WheelJoint_IsSteeringLimitEnabled(jointId: b3JointId) bool;
/// Get the wheel joint lower steering limit in radians.
pub extern fn b3WheelJoint_GetLowerSteeringLimit(jointId: b3JointId) f32;
/// Get the wheel joint upper steering limit in radians.
pub extern fn b3WheelJoint_GetUpperSteeringLimit(jointId: b3JointId) f32;
/// Set the wheel joint steering limits in radians.
pub extern fn b3WheelJoint_SetSteeringLimits(jointId: b3JointId, lowerRadians: f32, upperRadians: f32) void;
/// Set the wheel joint target steering angle in radians.
pub extern fn b3WheelJoint_SetTargetSteeringAngle(jointId: b3JointId, radians: f32) void;
/// Get the wheel joint target steering angle in radians.
pub extern fn b3WheelJoint_GetTargetSteeringAngle(jointId: b3JointId) f32;
/// Get the current steering angle in radians.
pub extern fn b3WheelJoint_GetSteeringAngle(jointId: b3JointId) f32;
/// Get the current steering torque in N*m.
pub extern fn b3WheelJoint_GetSteeringTorque(jointId: b3JointId) f32;
/// Contact identifier validation. Provides validation for up to 2^32 allocations.
pub extern fn b3Contact_IsValid(id: b3ContactId) bool;
/// Get the manifolds for a contact. The manifold may have no points if the contact is not touching.
pub extern fn b3Contact_GetData(contactId: b3ContactId) b3ContactData;

pub const __VERSION__ = "Aro aro-zig";
pub const __Aro__ = "";
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const __STDC_EMBED_NOT_FOUND__ = @as(c_int, 0);
pub const __STDC_EMBED_FOUND__ = @as(c_int, 1);
pub const __STDC_EMBED_EMPTY__ = @as(c_int, 2);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __GNUC__ = @as(c_int, 7);
pub const __GNUC_MINOR__ = @as(c_int, 1);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 0);
pub const __ARO_EMULATE_NO__ = @as(c_int, 0);
pub const __ARO_EMULATE_CLANG__ = @as(c_int, 1);
pub const __ARO_EMULATE_GCC__ = @as(c_int, 2);
pub const __ARO_EMULATE_MSVC__ = @as(c_int, 3);
pub const __ARO_EMULATE__ = __ARO_EMULATE_GCC__;
pub inline fn __building_module(x: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &x;
    return @as(c_int, 0);
}
pub const linux = @as(c_int, 1);
pub const __linux = @as(c_int, 1);
pub const __linux__ = @as(c_int, 1);
pub const unix = @as(c_int, 1);
pub const __unix = @as(c_int, 1);
pub const __unix__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `address_space`"); // <builtin>:33:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `address_space`"); // <builtin>:34:9
pub const __FXSR__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __SIZEOF_FLOAT128__ = @as(c_int, 16);
pub const _LP64 = @as(c_int, 1);
pub const __LP64__ = @as(c_int, 1);
pub const __FLOAT128__ = @as(c_int, 1);
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const __ELF__ = @as(c_int, 1);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __ATOMIC_BOOL_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_WINT_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_SHORT_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_INT_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_LONG_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_LLONG_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_POINTER_LOCK_FREE = @as(c_int, 1);
pub const __WINT_UNSIGNED__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 8);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SCHAR_WIDTH__ = @as(c_int, 8);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __LONG_WIDTH__ = @as(c_int, 64);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __LONG_LONG_WIDTH__ = @as(c_int, 64);
pub const __WCHAR_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 32);
pub const __WINT_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 32);
pub const __INTMAX_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIG_ATOMIC_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __BITINT_MAXWIDTH__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 10);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 8);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 4);
pub const __SIZEOF_WINT_T__ = @as(c_int, 4);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTPTR_TYPE__ = c_long;
pub const __UINTPTR_TYPE__ = c_ulong;
pub const __INTMAX_TYPE__ = c_long;
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`"); // <builtin>:116:9
pub const __INTMAX_C = __helpers.L_SUFFIX;
pub const __UINTMAX_TYPE__ = c_ulong;
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`"); // <builtin>:119:9
pub const __UINTMAX_C = __helpers.UL_SUFFIX;
pub const __PTRDIFF_TYPE__ = c_long;
pub const __SIZE_TYPE__ = c_ulong;
pub const __WCHAR_TYPE__ = c_int;
pub const __WINT_TYPE__ = c_uint;
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub inline fn __INT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub inline fn __INT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub inline fn __INT32_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT64_TYPE__ = c_long;
pub const __INT64_FMTd__ = "ld";
pub const __INT64_FMTi__ = "li";
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`"); // <builtin>:145:9
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub inline fn __UINT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub inline fn __UINT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`"); // <builtin>:170:9
pub const __UINT32_C = __helpers.U_SUFFIX;
pub const __UINT32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulong;
pub const __UINT64_FMTo__ = "lo";
pub const __UINT64_FMTu__ = "lu";
pub const __UINT64_FMTx__ = "lx";
pub const __UINT64_FMTX__ = "lX";
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`"); // <builtin>:179:9
pub const __UINT64_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __INT64_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const INT_LEAST8_FMTd__ = "hhd";
pub const INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const UINT_LEAST8_FMTo__ = "hho";
pub const UINT_LEAST8_FMTu__ = "hhu";
pub const UINT_LEAST8_FMTx__ = "hhx";
pub const UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const INT_FAST8_FMTd__ = "hhd";
pub const INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const UINT_FAST8_FMTo__ = "hho";
pub const UINT_FAST8_FMTu__ = "hhu";
pub const UINT_FAST8_FMTx__ = "hhx";
pub const UINT_FAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const INT_LEAST16_FMTd__ = "hd";
pub const INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_LEAST16_FMTo__ = "ho";
pub const UINT_LEAST16_FMTu__ = "hu";
pub const UINT_LEAST16_FMTx__ = "hx";
pub const UINT_LEAST16_FMTX__ = "hX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const INT_FAST16_FMTd__ = "hd";
pub const INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_FAST16_FMTo__ = "ho";
pub const UINT_FAST16_FMTu__ = "hu";
pub const UINT_FAST16_FMTx__ = "hx";
pub const UINT_FAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const INT_LEAST32_FMTd__ = "d";
pub const INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_LEAST32_FMTo__ = "o";
pub const UINT_LEAST32_FMTu__ = "u";
pub const UINT_LEAST32_FMTx__ = "x";
pub const UINT_LEAST32_FMTX__ = "X";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const INT_FAST32_FMTd__ = "d";
pub const INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_FAST32_FMTo__ = "o";
pub const UINT_FAST32_FMTu__ = "u";
pub const UINT_FAST32_FMTx__ = "x";
pub const UINT_FAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_long;
pub const __INT_LEAST64_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const INT_LEAST64_FMTd__ = "ld";
pub const INT_LEAST64_FMTi__ = "li";
pub const __UINT_LEAST64_TYPE__ = c_ulong;
pub const __UINT_LEAST64_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_LEAST64_FMTo__ = "lo";
pub const UINT_LEAST64_FMTu__ = "lu";
pub const UINT_LEAST64_FMTx__ = "lx";
pub const UINT_LEAST64_FMTX__ = "lX";
pub const __INT_FAST64_TYPE__ = c_long;
pub const __INT_FAST64_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const INT_FAST64_FMTd__ = "ld";
pub const INT_FAST64_FMTi__ = "li";
pub const __UINT_FAST64_TYPE__ = c_ulong;
pub const __UINT_FAST64_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_FAST64_FMTo__ = "lo";
pub const UINT_FAST64_FMTu__ = "lu";
pub const UINT_FAST64_FMTx__ = "lx";
pub const UINT_FAST64_FMTX__ = "lX";
pub const __FLT16_DENORM_MIN__ = @as(f16, 5.9604644775390625e-8);
pub const __FLT16_HAS_DENORM__ = "";
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_EPSILON__ = @as(f16, 9.765625e-4);
pub const __FLT16_HAS_INFINITY__ = "";
pub const __FLT16_HAS_QUIET_NAN__ = "";
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT16_MIN__ = @as(f16, 6.103515625e-5);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_HAS_DENORM__ = "";
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = "";
pub const __FLT_HAS_QUIET_NAN__ = "";
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = @as(f64, 4.9406564584124654e-324);
pub const __DBL_HAS_DENORM__ = "";
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = @as(f64, 2.2204460492503131e-16);
pub const __DBL_HAS_INFINITY__ = "";
pub const __DBL_HAS_QUIET_NAN__ = "";
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = @as(f64, 2.2250738585072014e-308);
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_HAS_DENORM__ = "";
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = "";
pub const __LDBL_HAS_QUIET_NAN__ = "";
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __FLT_EVAL_METHOD__ = @as(c_int, 0);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __pic__ = @as(c_int, 2);
pub const __PIC__ = @as(c_int, 2);
pub const __GLIBC_MINOR__ = @as(c_int, 31);
pub const @"bool" = bool;
pub const @"true" = @as(c_int, 1);
pub const @"false" = @as(c_int, 0);
pub const __bool_true_false_are_defined = @as(c_int, 1);
pub const __CLANG_STDINT_H = "";
pub const _STDINT_H = @as(c_int, 1);
pub const _FEATURES_H = @as(c_int, 1);
pub const __KERNEL_STRICT_NAMES = "";
pub inline fn __GNUC_PREREQ(maj: anytype, min: anytype) @TypeOf(((__GNUC__ << @as(c_int, 16)) + __GNUC_MINOR__) >= ((maj << @as(c_int, 16)) + min)) {
    _ = &maj;
    _ = &min;
    return ((__GNUC__ << @as(c_int, 16)) + __GNUC_MINOR__) >= ((maj << @as(c_int, 16)) + min);
}
pub inline fn __glibc_clang_prereq(maj: anytype, min: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &maj;
    _ = &min;
    return @as(c_int, 0);
}
pub const __GLIBC_USE = @compileError("unable to translate macro: undefined identifier `__GLIBC_USE_`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/features.h:197:9
pub const _DEFAULT_SOURCE = @as(c_int, 1);
pub const __GLIBC_USE_ISOC2Y = @as(c_int, 0);
pub const __GLIBC_USE_ISOC23 = @as(c_int, 0);
pub const __USE_ISOC11 = @as(c_int, 1);
pub const __USE_POSIX_IMPLICITLY = @as(c_int, 1);
pub const _POSIX_SOURCE = @as(c_int, 1);
pub const _POSIX_C_SOURCE = @as(c_long, 202405);
pub const __USE_POSIX = @as(c_int, 1);
pub const __USE_POSIX2 = @as(c_int, 1);
pub const __USE_POSIX199309 = @as(c_int, 1);
pub const __USE_POSIX199506 = @as(c_int, 1);
pub const __USE_XOPEN2K = @as(c_int, 1);
pub const __USE_ISOC95 = @as(c_int, 1);
pub const __USE_ISOC99 = @as(c_int, 1);
pub const __USE_XOPEN2K8 = @as(c_int, 1);
pub const _ATFILE_SOURCE = @as(c_int, 1);
pub const __USE_XOPEN2K24 = @as(c_int, 1);
pub const __WORDSIZE = @as(c_int, 64);
pub const __WORDSIZE_TIME64_COMPAT32 = @as(c_int, 1);
pub const __SYSCALL_WORDSIZE = @as(c_int, 64);
pub const __TIMESIZE = __WORDSIZE;
pub const __USE_TIME_BITS64 = @as(c_int, 1);
pub const __USE_MISC = @as(c_int, 1);
pub const __USE_ATFILE = @as(c_int, 1);
pub const __USE_FORTIFY_LEVEL = @as(c_int, 0);
pub const __GLIBC_USE_DEPRECATED_GETS = @as(c_int, 0);
pub const __GLIBC_USE_DEPRECATED_SCANF = @as(c_int, 0);
pub const __GLIBC_USE_C23_STRTOL = @as(c_int, 0);
pub const _STDC_PREDEF_H = @as(c_int, 1);
pub const __STDC_IEC_559__ = @as(c_int, 1);
pub const __STDC_IEC_60559_BFP__ = @as(c_long, 201404);
pub const __STDC_IEC_559_COMPLEX__ = @as(c_int, 1);
pub const __STDC_IEC_60559_COMPLEX__ = @as(c_long, 201404);
pub const __STDC_ISO_10646__ = @as(c_long, 201706);
pub const __GNU_LIBRARY__ = @as(c_int, 6);
pub const __GLIBC__ = @as(c_int, 2);
pub inline fn __GLIBC_PREREQ(maj: anytype, min: anytype) @TypeOf(((__GLIBC__ << @as(c_int, 16)) + __GLIBC_MINOR__) >= ((maj << @as(c_int, 16)) + min)) {
    _ = &maj;
    _ = &min;
    return ((__GLIBC__ << @as(c_int, 16)) + __GLIBC_MINOR__) >= ((maj << @as(c_int, 16)) + min);
}
pub const _SYS_CDEFS_H = @as(c_int, 1);
pub const __glibc_has_attribute = @compileError("unable to translate macro: undefined identifier `__has_attribute`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:45:10
pub inline fn __glibc_has_builtin(name: anytype) @TypeOf(__builtin.has_builtin(name)) {
    _ = &name;
    return __builtin.has_builtin(name);
}
pub const __glibc_has_extension = @compileError("unable to translate macro: undefined identifier `__has_extension`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:55:10
pub const __LEAF = @compileError("unable to translate macro: undefined identifier `__leaf__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:65:11
pub const __LEAF_ATTR = @compileError("unable to translate macro: undefined identifier `__leaf__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:66:11
pub const __THROW = @compileError("unable to translate macro: undefined identifier `__nothrow__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:79:11
pub const __THROWNL = @compileError("unable to translate macro: undefined identifier `__nothrow__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:80:11
pub const __NTH = @compileError("unable to translate macro: undefined identifier `__nothrow__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:81:11
pub const __NTHNL = @compileError("unable to translate macro: undefined identifier `__nothrow__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:82:11
pub const __COLD = @compileError("unable to translate macro: undefined identifier `__cold__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:102:11
pub inline fn __P(args: anytype) @TypeOf(args) {
    _ = &args;
    return args;
}
pub inline fn __PMT(args: anytype) @TypeOf(args) {
    _ = &args;
    return args;
}
pub const __CONCAT = @compileError("unable to translate C expr: unexpected token '##'"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:131:9
pub const __STRING = @compileError("unable to translate C expr: unexpected token ''"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:132:9
pub const __ptr_t = ?*anyopaque;
pub const __BEGIN_DECLS = "";
pub const __END_DECLS = "";
pub const __attribute_overloadable__ = "";
pub inline fn __bos(ptr: anytype) @TypeOf(__builtin.object_size(ptr, __USE_FORTIFY_LEVEL > @as(c_int, 1))) {
    _ = &ptr;
    return __builtin.object_size(ptr, __USE_FORTIFY_LEVEL > @as(c_int, 1));
}
pub inline fn __bos0(ptr: anytype) @TypeOf(__builtin.object_size(ptr, @as(c_int, 0))) {
    _ = &ptr;
    return __builtin.object_size(ptr, @as(c_int, 0));
}
pub inline fn __glibc_objsize0(__o: anytype) @TypeOf(__bos0(__o)) {
    _ = &__o;
    return __bos0(__o);
}
pub inline fn __glibc_objsize(__o: anytype) @TypeOf(__bos(__o)) {
    _ = &__o;
    return __bos(__o);
}
pub const __warnattr = @compileError("unable to translate macro: undefined identifier `__warning__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:366:10
pub const __errordecl = @compileError("unable to translate macro: undefined identifier `__error__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:367:10
pub const __flexarr = @compileError("unable to translate C expr: unexpected token '['"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:379:10
pub const __glibc_c99_flexarr_available = @as(c_int, 1);
pub const __REDIRECT = @compileError("unable to translate C expr: unexpected token '__asm__'"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:410:10
pub const __REDIRECT_NTH = @compileError("unable to translate C expr: unexpected token '__asm__'"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:417:11
pub const __REDIRECT_NTHNL = @compileError("unable to translate C expr: unexpected token '__asm__'"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:419:11
pub const __ASMNAME = @compileError("unable to translate macro: undefined identifier `__USER_LABEL_PREFIX__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:422:10
pub inline fn __ASMNAME2(prefix: anytype, cname: anytype) @TypeOf(__STRING(prefix) ++ cname) {
    _ = &prefix;
    _ = &cname;
    return __STRING(prefix) ++ cname;
}
pub const __REDIRECT_FORTIFY = __REDIRECT;
pub const __REDIRECT_FORTIFY_NTH = __REDIRECT_NTH;
pub const __attribute_malloc__ = @compileError("unable to translate macro: undefined identifier `__malloc__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:452:10
pub const __attribute_alloc_size__ = @compileError("unable to translate macro: undefined identifier `__alloc_size__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:460:10
pub const __attribute_alloc_align__ = @compileError("unable to translate macro: undefined identifier `__alloc_align__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:469:10
pub const __attribute_pure__ = @compileError("unable to translate macro: undefined identifier `__pure__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:479:10
pub const __attribute_const__ = @compileError("unable to translate C expr: unexpected token '__attribute__'"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:486:10
pub const __attribute_maybe_unused__ = @compileError("unable to translate macro: undefined identifier `__unused__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:492:10
pub const __attribute_used__ = @compileError("unable to translate macro: undefined identifier `__used__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:501:10
pub const __attribute_noinline__ = @compileError("unable to translate macro: undefined identifier `__noinline__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:502:10
pub const __attribute_deprecated__ = @compileError("unable to translate macro: undefined identifier `__deprecated__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:510:10
pub const __attribute_deprecated_msg__ = @compileError("unable to translate macro: undefined identifier `__deprecated__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:520:10
pub const __attribute_format_arg__ = @compileError("unable to translate macro: undefined identifier `__format_arg__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:533:10
pub const __attribute_format_strfmon__ = @compileError("unable to translate macro: undefined identifier `__format__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:543:10
pub const __attribute_nonnull__ = @compileError("unable to translate macro: undefined identifier `__nonnull__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:555:11
pub inline fn __nonnull(params: anytype) @TypeOf(__attribute_nonnull__(params)) {
    _ = &params;
    return __attribute_nonnull__(params);
}
pub const __returns_nonnull = @compileError("unable to translate macro: undefined identifier `__returns_nonnull__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:568:10
pub const __attribute_warn_unused_result__ = @compileError("unable to translate macro: undefined identifier `__warn_unused_result__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:577:10
pub const __wur = "";
pub const __always_inline = @compileError("unable to translate macro: undefined identifier `__always_inline__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:595:10
pub const __attribute_artificial__ = @compileError("unable to translate macro: undefined identifier `__artificial__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:604:10
pub const __extern_inline = @compileError("unable to translate C expr: unexpected token 'extern'"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:626:11
pub const __extern_always_inline = @compileError("unable to translate C expr: unexpected token 'extern'"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:627:11
pub const __fortify_function = __extern_always_inline ++ __attribute_artificial__;
pub const __va_arg_pack = @compileError("unable to translate macro: undefined identifier `__builtin_va_arg_pack`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:638:10
pub const __va_arg_pack_len = @compileError("unable to translate macro: undefined identifier `__builtin_va_arg_pack_len`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:639:10
pub const __restrict_arr = @compileError("unable to translate C expr: unexpected token '__restrict'"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:666:10
pub inline fn __glibc_unlikely(cond: anytype) @TypeOf(__builtin.expect(cond, @as(c_int, 0))) {
    _ = &cond;
    return __builtin.expect(cond, @as(c_int, 0));
}
pub inline fn __glibc_likely(cond: anytype) @TypeOf(__builtin.expect(cond, @as(c_int, 1))) {
    _ = &cond;
    return __builtin.expect(cond, @as(c_int, 1));
}
pub const __attribute_nonstring__ = "";
pub inline fn __attribute_copy__(arg: anytype) void {
    _ = &arg;
    return;
}
pub const __LDOUBLE_REDIRECTS_TO_FLOAT128_ABI = @as(c_int, 0);
pub inline fn __LDBL_REDIR1(name: anytype, proto: anytype, alias: anytype) @TypeOf(name ++ proto) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return name ++ proto;
}
pub inline fn __LDBL_REDIR(name: anytype, proto: anytype) @TypeOf(name ++ proto) {
    _ = &name;
    _ = &proto;
    return name ++ proto;
}
pub inline fn __LDBL_REDIR1_NTH(name: anytype, proto: anytype, alias: anytype) @TypeOf(name ++ proto ++ __THROW) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return name ++ proto ++ __THROW;
}
pub inline fn __LDBL_REDIR_NTH(name: anytype, proto: anytype) @TypeOf(name ++ proto ++ __THROW) {
    _ = &name;
    _ = &proto;
    return name ++ proto ++ __THROW;
}
pub inline fn __LDBL_REDIR2_DECL(name: anytype) void {
    _ = &name;
    return;
}
pub inline fn __LDBL_REDIR_DECL(name: anytype) void {
    _ = &name;
    return;
}
pub inline fn __REDIRECT_LDBL(name: anytype, proto: anytype, alias: anytype) @TypeOf(__REDIRECT(name, proto, alias)) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return __REDIRECT(name, proto, alias);
}
pub inline fn __REDIRECT_NTH_LDBL(name: anytype, proto: anytype, alias: anytype) @TypeOf(__REDIRECT_NTH(name, proto, alias)) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return __REDIRECT_NTH(name, proto, alias);
}
pub const __glibc_macro_warning1 = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:807:10
pub const __glibc_macro_warning = @compileError("unable to translate macro: undefined identifier `GCC`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:808:10
pub const __HAVE_GENERIC_SELECTION = @as(c_int, 1);
pub const __glibc_const_generic = @compileError("unable to translate C expr: expected type instead got 'const'"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:837:10
pub inline fn __fortified_attr_access(a: anytype, o: anytype, s: anytype) void {
    _ = &a;
    _ = &o;
    _ = &s;
    return;
}
pub inline fn __attr_access(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __attr_access_none(argno: anytype) void {
    _ = &argno;
    return;
}
pub inline fn __attr_dealloc(dealloc: anytype, argno: anytype) void {
    _ = &dealloc;
    _ = &argno;
    return;
}
pub const __attr_dealloc_free = "";
pub const __attribute_returns_twice__ = @compileError("unable to translate macro: undefined identifier `__returns_twice__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:884:10
pub const __attribute_struct_may_alias__ = @compileError("unable to translate macro: undefined identifier `__may_alias__`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/sys/cdefs.h:893:10
pub const __stub___compat_bdflush = "";
pub const __stub_chflags = "";
pub const __stub_fchflags = "";
pub const __stub_gtty = "";
pub const __stub_revoke = "";
pub const __stub_setlogin = "";
pub const __stub_sigreturn = "";
pub const __stub_stty = "";
pub const _BITS_TYPES_H = @as(c_int, 1);
pub const __S16_TYPE = c_short;
pub const __U16_TYPE = c_ushort;
pub const __S32_TYPE = c_int;
pub const __U32_TYPE = c_uint;
pub const __SLONGWORD_TYPE = c_long;
pub const __ULONGWORD_TYPE = c_ulong;
pub const __SQUAD_TYPE = c_long;
pub const __UQUAD_TYPE = c_ulong;
pub const __SWORD_TYPE = c_long;
pub const __UWORD_TYPE = c_ulong;
pub const __SLONG32_TYPE = c_int;
pub const __ULONG32_TYPE = c_uint;
pub const __S64_TYPE = c_long;
pub const __U64_TYPE = c_ulong;
pub const _BITS_TYPESIZES_H = @as(c_int, 1);
pub const __SYSCALL_SLONG_TYPE = __SLONGWORD_TYPE;
pub const __SYSCALL_ULONG_TYPE = __ULONGWORD_TYPE;
pub const __DEV_T_TYPE = __UQUAD_TYPE;
pub const __UID_T_TYPE = __U32_TYPE;
pub const __GID_T_TYPE = __U32_TYPE;
pub const __INO_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __INO64_T_TYPE = __UQUAD_TYPE;
pub const __MODE_T_TYPE = __U32_TYPE;
pub const __NLINK_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __FSWORD_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __OFF_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __OFF64_T_TYPE = __SQUAD_TYPE;
pub const __PID_T_TYPE = __S32_TYPE;
pub const __RLIM_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __RLIM64_T_TYPE = __UQUAD_TYPE;
pub const __BLKCNT_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __BLKCNT64_T_TYPE = __SQUAD_TYPE;
pub const __FSBLKCNT_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __FSBLKCNT64_T_TYPE = __UQUAD_TYPE;
pub const __FSFILCNT_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __FSFILCNT64_T_TYPE = __UQUAD_TYPE;
pub const __ID_T_TYPE = __U32_TYPE;
pub const __CLOCK_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __TIME_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __USECONDS_T_TYPE = __U32_TYPE;
pub const __SUSECONDS_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __SUSECONDS64_T_TYPE = __SQUAD_TYPE;
pub const __DADDR_T_TYPE = __S32_TYPE;
pub const __KEY_T_TYPE = __S32_TYPE;
pub const __CLOCKID_T_TYPE = __S32_TYPE;
pub const __TIMER_T_TYPE = ?*anyopaque;
pub const __BLKSIZE_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __FSID_T_TYPE = @compileError("unable to translate macro: undefined identifier `__val`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/x86-linux-gnu/bits/typesizes.h:73:9
pub const __SSIZE_T_TYPE = __SWORD_TYPE;
pub const __CPU_MASK_TYPE = __SYSCALL_ULONG_TYPE;
pub const __OFF_T_MATCHES_OFF64_T = @as(c_int, 1);
pub const __INO_T_MATCHES_INO64_T = @as(c_int, 1);
pub const __RLIM_T_MATCHES_RLIM64_T = @as(c_int, 1);
pub const __STATFS_MATCHES_STATFS64 = @as(c_int, 1);
pub const __KERNEL_OLD_TIMEVAL_MATCHES_TIMEVAL64 = @as(c_int, 1);
pub const __FD_SETSIZE = @as(c_int, 1024);
pub const _BITS_TIME64_H = @as(c_int, 1);
pub const __TIME64_T_TYPE = __TIME_T_TYPE;
pub const _BITS_WCHAR_H = @as(c_int, 1);
pub const __WCHAR_MAX = __WCHAR_MAX__;
pub const __WCHAR_MIN = -__WCHAR_MAX - @as(c_int, 1);
pub const _BITS_STDINT_INTN_H = @as(c_int, 1);
pub const _BITS_STDINT_UINTN_H = @as(c_int, 1);
pub const _BITS_STDINT_LEAST_H = @as(c_int, 1);
pub const __intptr_t_defined = "";
pub const __INT64_C = __helpers.L_SUFFIX;
pub const __UINT64_C = __helpers.UL_SUFFIX;
pub const INT8_MIN = -@as(c_int, 128);
pub const INT16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const INT32_MIN = -__helpers.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT64_MIN = -__INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT8_MAX = @as(c_int, 127);
pub const INT16_MAX = @as(c_int, 32767);
pub const INT32_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT64_MAX = __INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT8_MAX = @as(c_int, 255);
pub const UINT16_MAX = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT32_MAX = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT64_MAX = __UINT64_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INT_LEAST8_MIN = -@as(c_int, 128);
pub const INT_LEAST16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const INT_LEAST32_MIN = -__helpers.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT_LEAST64_MIN = -__INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT_LEAST8_MAX = @as(c_int, 127);
pub const INT_LEAST16_MAX = @as(c_int, 32767);
pub const INT_LEAST32_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT_LEAST64_MAX = __INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT_LEAST8_MAX = @as(c_int, 255);
pub const UINT_LEAST16_MAX = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_LEAST32_MAX = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_LEAST64_MAX = __UINT64_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INT_FAST8_MIN = -@as(c_int, 128);
pub const INT_FAST16_MIN = -__helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INT_FAST32_MIN = -__helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INT_FAST64_MIN = -__INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT_FAST8_MAX = @as(c_int, 127);
pub const INT_FAST16_MAX = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const INT_FAST32_MAX = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const INT_FAST64_MAX = __INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT_FAST8_MAX = @as(c_int, 255);
pub const UINT_FAST16_MAX = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_FAST32_MAX = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_FAST64_MAX = __UINT64_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INTPTR_MIN = -__helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INTPTR_MAX = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const UINTPTR_MAX = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const INTMAX_MIN = -__INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INTMAX_MAX = __INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINTMAX_MAX = __UINT64_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const PTRDIFF_MIN = -__helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const PTRDIFF_MAX = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const SIG_ATOMIC_MIN = -__helpers.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const SIG_ATOMIC_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const SIZE_MAX = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const WCHAR_MIN = __WCHAR_MIN;
pub const WCHAR_MAX = __WCHAR_MAX;
pub const WINT_MIN = @as(c_uint, 0);
pub const WINT_MAX = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub inline fn INT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn INT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn INT32_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const INT64_C = __helpers.L_SUFFIX;
pub inline fn UINT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn UINT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const UINT32_C = __helpers.U_SUFFIX;
pub const UINT64_C = __helpers.UL_SUFFIX;
pub const INTMAX_C = __helpers.L_SUFFIX;
pub const UINTMAX_C = __helpers.UL_SUFFIX;
pub const BOX3D_EXPORT = "";
pub const B3_API = "";
pub const B3_INLINE = @compileError("unable to translate C expr: unexpected token 'static'"); // box3d/include/box3d/base.h:54:10
pub const B3_ALIGN_AS = @compileError("unable to translate C expr: unexpected token '_Alignas'"); // box3d/include/box3d/base.h:55:10
pub const B3_FORCE_INLINE = @compileError("unable to translate macro: undefined identifier `always_inline`"); // box3d/include/box3d/base.h:60:10
/// Used for C literals like (b3Vec3){1.0f, 2.0f, 3.0f} where C++ requires b3Vec3{1.0f, 2.0f, 3.0f}
pub inline fn B3_LITERAL(T: anytype) @TypeOf(T) {
    _ = &T;
    return T;
}
pub const B3_ZERO_INIT = @compileError("unable to translate C expr: unexpected token '{'"); // box3d/include/box3d/base.h:67:10
pub const B3_PRINTF_FORMAT = @compileError("unable to translate macro: undefined identifier `format`"); // box3d/include/box3d/base.h:73:9
pub const B3_ENABLE_VALIDATION = @as(c_int, 0);
/// This is used to indicate null for interfaces that work with indices instead of pointers
pub const B3_NULL_INDEX = -@as(c_int, 1);
/// Unknown compiler
pub const B3_BREAKPOINT = @compileError("unable to translate macro: undefined identifier `__builtin_trap`"); // box3d/include/box3d/base.h:124:9
/// Assert that a condition is true.
pub const B3_ASSERT = @compileError("unable to translate macro: undefined identifier `__FILE__`"); // box3d/include/box3d/base.h:135:9
/// Validation is typically only enabled in debug builds.
/// Floating point tolerance checks should use this instead of the regular assertion
pub inline fn B3_VALIDATE() anyopaque {
    return __helpers.cast(anyopaque, @as(c_int, 0));
}
pub const B3_HASH_INIT = @as(c_int, 5381);
pub const FLT_RADIX = __FLT_RADIX__;
pub const FLT_MANT_DIG = __FLT_MANT_DIG__;
pub const DBL_MANT_DIG = __DBL_MANT_DIG__;
pub const LDBL_MANT_DIG = __LDBL_MANT_DIG__;
pub const FLT_EVAL_METHOD = __FLT_EVAL_METHOD__;
pub const DECIMAL_DIG = __DECIMAL_DIG__;
pub const FLT_DIG = __FLT_DIG__;
pub const DBL_DIG = __DBL_DIG__;
pub const LDBL_DIG = __LDBL_DIG__;
pub const FLT_MIN_EXP = __FLT_MIN_EXP__;
pub const DBL_MIN_EXP = __DBL_MIN_EXP__;
pub const LDBL_MIN_EXP = __LDBL_MIN_EXP__;
pub const FLT_MIN_10_EXP = __FLT_MIN_10_EXP__;
pub const DBL_MIN_10_EXP = __DBL_MIN_10_EXP__;
pub const LDBL_MIN_10_EXP = __LDBL_MIN_10_EXP__;
pub const FLT_MAX_EXP = __FLT_MAX_EXP__;
pub const DBL_MAX_EXP = __DBL_MAX_EXP__;
pub const LDBL_MAX_EXP = __LDBL_MAX_EXP__;
pub const FLT_MAX_10_EXP = __FLT_MAX_10_EXP__;
pub const DBL_MAX_10_EXP = __DBL_MAX_10_EXP__;
pub const LDBL_MAX_10_EXP = __LDBL_MAX_10_EXP__;
pub const FLT_MAX = __FLT_MAX__;
pub const DBL_MAX = __DBL_MAX__;
pub const LDBL_MAX = __LDBL_MAX__;
pub const FLT_EPSILON = __FLT_EPSILON__;
pub const DBL_EPSILON = __DBL_EPSILON__;
pub const LDBL_EPSILON = __LDBL_EPSILON__;
pub const FLT_MIN = __FLT_MIN__;
pub const DBL_MIN = __DBL_MIN__;
pub const LDBL_MIN = __LDBL_MIN__;
pub const FLT_TRUE_MIN = __FLT_DENORM_MIN__;
pub const DBL_TRUE_MIN = __DBL_DENORM_MIN__;
pub const LDBL_TRUE_MIN = __LDBL_DENORM_MIN__;
pub const FLT_DECIMAL_DIG = __FLT_DECIMAL_DIG__;
pub const DBL_DECIMAL_DIG = __DBL_DECIMAL_DIG__;
pub const LDBL_DECIMAL_DIG = __LDBL_DECIMAL_DIG__;
pub const FLT_HAS_SUBNORM = "";
pub const DBL_HAS_SUBNORM = "";
pub const LDBL_HAS_SUBNORM = "";
pub const _MATH_H = @as(c_int, 1);
pub const __GLIBC_USE_LIB_EXT2 = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_BFP_EXT = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_BFP_EXT_C23 = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_EXT = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_FUNCS_EXT = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_FUNCS_EXT_C23 = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_TYPES_EXT = @as(c_int, 0);
pub const _BITS_LIBM_SIMD_DECL_STUBS_H = @as(c_int, 1);
pub const __DECL_SIMD_cos = "";
pub const __DECL_SIMD_cosf = "";
pub const __DECL_SIMD_cosl = "";
pub const __DECL_SIMD_cosf16 = "";
pub const __DECL_SIMD_cosf32 = "";
pub const __DECL_SIMD_cosf64 = "";
pub const __DECL_SIMD_cosf128 = "";
pub const __DECL_SIMD_cosf32x = "";
pub const __DECL_SIMD_cosf64x = "";
pub const __DECL_SIMD_cosf128x = "";
pub const __DECL_SIMD_sin = "";
pub const __DECL_SIMD_sinf = "";
pub const __DECL_SIMD_sinl = "";
pub const __DECL_SIMD_sinf16 = "";
pub const __DECL_SIMD_sinf32 = "";
pub const __DECL_SIMD_sinf64 = "";
pub const __DECL_SIMD_sinf128 = "";
pub const __DECL_SIMD_sinf32x = "";
pub const __DECL_SIMD_sinf64x = "";
pub const __DECL_SIMD_sinf128x = "";
pub const __DECL_SIMD_sincos = "";
pub const __DECL_SIMD_sincosf = "";
pub const __DECL_SIMD_sincosl = "";
pub const __DECL_SIMD_sincosf16 = "";
pub const __DECL_SIMD_sincosf32 = "";
pub const __DECL_SIMD_sincosf64 = "";
pub const __DECL_SIMD_sincosf128 = "";
pub const __DECL_SIMD_sincosf32x = "";
pub const __DECL_SIMD_sincosf64x = "";
pub const __DECL_SIMD_sincosf128x = "";
pub const __DECL_SIMD_log = "";
pub const __DECL_SIMD_logf = "";
pub const __DECL_SIMD_logl = "";
pub const __DECL_SIMD_logf16 = "";
pub const __DECL_SIMD_logf32 = "";
pub const __DECL_SIMD_logf64 = "";
pub const __DECL_SIMD_logf128 = "";
pub const __DECL_SIMD_logf32x = "";
pub const __DECL_SIMD_logf64x = "";
pub const __DECL_SIMD_logf128x = "";
pub const __DECL_SIMD_exp = "";
pub const __DECL_SIMD_expf = "";
pub const __DECL_SIMD_expl = "";
pub const __DECL_SIMD_expf16 = "";
pub const __DECL_SIMD_expf32 = "";
pub const __DECL_SIMD_expf64 = "";
pub const __DECL_SIMD_expf128 = "";
pub const __DECL_SIMD_expf32x = "";
pub const __DECL_SIMD_expf64x = "";
pub const __DECL_SIMD_expf128x = "";
pub const __DECL_SIMD_pow = "";
pub const __DECL_SIMD_powf = "";
pub const __DECL_SIMD_powl = "";
pub const __DECL_SIMD_powf16 = "";
pub const __DECL_SIMD_powf32 = "";
pub const __DECL_SIMD_powf64 = "";
pub const __DECL_SIMD_powf128 = "";
pub const __DECL_SIMD_powf32x = "";
pub const __DECL_SIMD_powf64x = "";
pub const __DECL_SIMD_powf128x = "";
pub const __DECL_SIMD_powr = "";
pub const __DECL_SIMD_powrf = "";
pub const __DECL_SIMD_powrl = "";
pub const __DECL_SIMD_powrf16 = "";
pub const __DECL_SIMD_powrf32 = "";
pub const __DECL_SIMD_powrf64 = "";
pub const __DECL_SIMD_powrf128 = "";
pub const __DECL_SIMD_powrf32x = "";
pub const __DECL_SIMD_powrf64x = "";
pub const __DECL_SIMD_powrf128x = "";
pub const __DECL_SIMD_acos = "";
pub const __DECL_SIMD_acosf = "";
pub const __DECL_SIMD_acosl = "";
pub const __DECL_SIMD_acosf16 = "";
pub const __DECL_SIMD_acosf32 = "";
pub const __DECL_SIMD_acosf64 = "";
pub const __DECL_SIMD_acosf128 = "";
pub const __DECL_SIMD_acosf32x = "";
pub const __DECL_SIMD_acosf64x = "";
pub const __DECL_SIMD_acosf128x = "";
pub const __DECL_SIMD_atan = "";
pub const __DECL_SIMD_atanf = "";
pub const __DECL_SIMD_atanl = "";
pub const __DECL_SIMD_atanf16 = "";
pub const __DECL_SIMD_atanf32 = "";
pub const __DECL_SIMD_atanf64 = "";
pub const __DECL_SIMD_atanf128 = "";
pub const __DECL_SIMD_atanf32x = "";
pub const __DECL_SIMD_atanf64x = "";
pub const __DECL_SIMD_atanf128x = "";
pub const __DECL_SIMD_asin = "";
pub const __DECL_SIMD_asinf = "";
pub const __DECL_SIMD_asinl = "";
pub const __DECL_SIMD_asinf16 = "";
pub const __DECL_SIMD_asinf32 = "";
pub const __DECL_SIMD_asinf64 = "";
pub const __DECL_SIMD_asinf128 = "";
pub const __DECL_SIMD_asinf32x = "";
pub const __DECL_SIMD_asinf64x = "";
pub const __DECL_SIMD_asinf128x = "";
pub const __DECL_SIMD_hypot = "";
pub const __DECL_SIMD_hypotf = "";
pub const __DECL_SIMD_hypotl = "";
pub const __DECL_SIMD_hypotf16 = "";
pub const __DECL_SIMD_hypotf32 = "";
pub const __DECL_SIMD_hypotf64 = "";
pub const __DECL_SIMD_hypotf128 = "";
pub const __DECL_SIMD_hypotf32x = "";
pub const __DECL_SIMD_hypotf64x = "";
pub const __DECL_SIMD_hypotf128x = "";
pub const __DECL_SIMD_exp2 = "";
pub const __DECL_SIMD_exp2f = "";
pub const __DECL_SIMD_exp2l = "";
pub const __DECL_SIMD_exp2f16 = "";
pub const __DECL_SIMD_exp2f32 = "";
pub const __DECL_SIMD_exp2f64 = "";
pub const __DECL_SIMD_exp2f128 = "";
pub const __DECL_SIMD_exp2f32x = "";
pub const __DECL_SIMD_exp2f64x = "";
pub const __DECL_SIMD_exp2f128x = "";
pub const __DECL_SIMD_exp10 = "";
pub const __DECL_SIMD_exp10f = "";
pub const __DECL_SIMD_exp10l = "";
pub const __DECL_SIMD_exp10f16 = "";
pub const __DECL_SIMD_exp10f32 = "";
pub const __DECL_SIMD_exp10f64 = "";
pub const __DECL_SIMD_exp10f128 = "";
pub const __DECL_SIMD_exp10f32x = "";
pub const __DECL_SIMD_exp10f64x = "";
pub const __DECL_SIMD_exp10f128x = "";
pub const __DECL_SIMD_cosh = "";
pub const __DECL_SIMD_coshf = "";
pub const __DECL_SIMD_coshl = "";
pub const __DECL_SIMD_coshf16 = "";
pub const __DECL_SIMD_coshf32 = "";
pub const __DECL_SIMD_coshf64 = "";
pub const __DECL_SIMD_coshf128 = "";
pub const __DECL_SIMD_coshf32x = "";
pub const __DECL_SIMD_coshf64x = "";
pub const __DECL_SIMD_coshf128x = "";
pub const __DECL_SIMD_expm1 = "";
pub const __DECL_SIMD_expm1f = "";
pub const __DECL_SIMD_expm1l = "";
pub const __DECL_SIMD_expm1f16 = "";
pub const __DECL_SIMD_expm1f32 = "";
pub const __DECL_SIMD_expm1f64 = "";
pub const __DECL_SIMD_expm1f128 = "";
pub const __DECL_SIMD_expm1f32x = "";
pub const __DECL_SIMD_expm1f64x = "";
pub const __DECL_SIMD_expm1f128x = "";
pub const __DECL_SIMD_exp2m1 = "";
pub const __DECL_SIMD_exp2m1f = "";
pub const __DECL_SIMD_exp2m1l = "";
pub const __DECL_SIMD_exp2m1f16 = "";
pub const __DECL_SIMD_exp2m1f32 = "";
pub const __DECL_SIMD_exp2m1f64 = "";
pub const __DECL_SIMD_exp2m1f128 = "";
pub const __DECL_SIMD_exp2m1f32x = "";
pub const __DECL_SIMD_exp2m1f64x = "";
pub const __DECL_SIMD_exp2m1f128x = "";
pub const __DECL_SIMD_exp10m1 = "";
pub const __DECL_SIMD_exp10m1f = "";
pub const __DECL_SIMD_exp10m1l = "";
pub const __DECL_SIMD_exp10m1f16 = "";
pub const __DECL_SIMD_exp10m1f32 = "";
pub const __DECL_SIMD_exp10m1f64 = "";
pub const __DECL_SIMD_exp10m1f128 = "";
pub const __DECL_SIMD_exp10m1f32x = "";
pub const __DECL_SIMD_exp10m1f64x = "";
pub const __DECL_SIMD_exp10m1f128x = "";
pub const __DECL_SIMD_sinh = "";
pub const __DECL_SIMD_sinhf = "";
pub const __DECL_SIMD_sinhl = "";
pub const __DECL_SIMD_sinhf16 = "";
pub const __DECL_SIMD_sinhf32 = "";
pub const __DECL_SIMD_sinhf64 = "";
pub const __DECL_SIMD_sinhf128 = "";
pub const __DECL_SIMD_sinhf32x = "";
pub const __DECL_SIMD_sinhf64x = "";
pub const __DECL_SIMD_sinhf128x = "";
pub const __DECL_SIMD_cbrt = "";
pub const __DECL_SIMD_cbrtf = "";
pub const __DECL_SIMD_cbrtl = "";
pub const __DECL_SIMD_cbrtf16 = "";
pub const __DECL_SIMD_cbrtf32 = "";
pub const __DECL_SIMD_cbrtf64 = "";
pub const __DECL_SIMD_cbrtf128 = "";
pub const __DECL_SIMD_cbrtf32x = "";
pub const __DECL_SIMD_cbrtf64x = "";
pub const __DECL_SIMD_cbrtf128x = "";
pub const __DECL_SIMD_atan2 = "";
pub const __DECL_SIMD_atan2f = "";
pub const __DECL_SIMD_atan2l = "";
pub const __DECL_SIMD_atan2f16 = "";
pub const __DECL_SIMD_atan2f32 = "";
pub const __DECL_SIMD_atan2f64 = "";
pub const __DECL_SIMD_atan2f128 = "";
pub const __DECL_SIMD_atan2f32x = "";
pub const __DECL_SIMD_atan2f64x = "";
pub const __DECL_SIMD_atan2f128x = "";
pub const __DECL_SIMD_rsqrt = "";
pub const __DECL_SIMD_rsqrtf = "";
pub const __DECL_SIMD_rsqrtl = "";
pub const __DECL_SIMD_rsqrtf16 = "";
pub const __DECL_SIMD_rsqrtf32 = "";
pub const __DECL_SIMD_rsqrtf64 = "";
pub const __DECL_SIMD_rsqrtf128 = "";
pub const __DECL_SIMD_rsqrtf32x = "";
pub const __DECL_SIMD_rsqrtf64x = "";
pub const __DECL_SIMD_rsqrtf128x = "";
pub const __DECL_SIMD_log10 = "";
pub const __DECL_SIMD_log10f = "";
pub const __DECL_SIMD_log10l = "";
pub const __DECL_SIMD_log10f16 = "";
pub const __DECL_SIMD_log10f32 = "";
pub const __DECL_SIMD_log10f64 = "";
pub const __DECL_SIMD_log10f128 = "";
pub const __DECL_SIMD_log10f32x = "";
pub const __DECL_SIMD_log10f64x = "";
pub const __DECL_SIMD_log10f128x = "";
pub const __DECL_SIMD_log10p1 = "";
pub const __DECL_SIMD_log10p1f = "";
pub const __DECL_SIMD_log10p1l = "";
pub const __DECL_SIMD_log10p1f16 = "";
pub const __DECL_SIMD_log10p1f32 = "";
pub const __DECL_SIMD_log10p1f64 = "";
pub const __DECL_SIMD_log10p1f128 = "";
pub const __DECL_SIMD_log10p1f32x = "";
pub const __DECL_SIMD_log10p1f64x = "";
pub const __DECL_SIMD_log10p1f128x = "";
pub const __DECL_SIMD_log2 = "";
pub const __DECL_SIMD_log2f = "";
pub const __DECL_SIMD_log2l = "";
pub const __DECL_SIMD_log2f16 = "";
pub const __DECL_SIMD_log2f32 = "";
pub const __DECL_SIMD_log2f64 = "";
pub const __DECL_SIMD_log2f128 = "";
pub const __DECL_SIMD_log2f32x = "";
pub const __DECL_SIMD_log2f64x = "";
pub const __DECL_SIMD_log2f128x = "";
pub const __DECL_SIMD_log2p1 = "";
pub const __DECL_SIMD_log2p1f = "";
pub const __DECL_SIMD_log2p1l = "";
pub const __DECL_SIMD_log2p1f16 = "";
pub const __DECL_SIMD_log2p1f32 = "";
pub const __DECL_SIMD_log2p1f64 = "";
pub const __DECL_SIMD_log2p1f128 = "";
pub const __DECL_SIMD_log2p1f32x = "";
pub const __DECL_SIMD_log2p1f64x = "";
pub const __DECL_SIMD_log2p1f128x = "";
pub const __DECL_SIMD_log1p = "";
pub const __DECL_SIMD_log1pf = "";
pub const __DECL_SIMD_log1pl = "";
pub const __DECL_SIMD_log1pf16 = "";
pub const __DECL_SIMD_log1pf32 = "";
pub const __DECL_SIMD_log1pf64 = "";
pub const __DECL_SIMD_log1pf128 = "";
pub const __DECL_SIMD_log1pf32x = "";
pub const __DECL_SIMD_log1pf64x = "";
pub const __DECL_SIMD_log1pf128x = "";
pub const __DECL_SIMD_logp1 = "";
pub const __DECL_SIMD_logp1f = "";
pub const __DECL_SIMD_logp1l = "";
pub const __DECL_SIMD_logp1f16 = "";
pub const __DECL_SIMD_logp1f32 = "";
pub const __DECL_SIMD_logp1f64 = "";
pub const __DECL_SIMD_logp1f128 = "";
pub const __DECL_SIMD_logp1f32x = "";
pub const __DECL_SIMD_logp1f64x = "";
pub const __DECL_SIMD_logp1f128x = "";
pub const __DECL_SIMD_atanh = "";
pub const __DECL_SIMD_atanhf = "";
pub const __DECL_SIMD_atanhl = "";
pub const __DECL_SIMD_atanhf16 = "";
pub const __DECL_SIMD_atanhf32 = "";
pub const __DECL_SIMD_atanhf64 = "";
pub const __DECL_SIMD_atanhf128 = "";
pub const __DECL_SIMD_atanhf32x = "";
pub const __DECL_SIMD_atanhf64x = "";
pub const __DECL_SIMD_atanhf128x = "";
pub const __DECL_SIMD_acosh = "";
pub const __DECL_SIMD_acoshf = "";
pub const __DECL_SIMD_acoshl = "";
pub const __DECL_SIMD_acoshf16 = "";
pub const __DECL_SIMD_acoshf32 = "";
pub const __DECL_SIMD_acoshf64 = "";
pub const __DECL_SIMD_acoshf128 = "";
pub const __DECL_SIMD_acoshf32x = "";
pub const __DECL_SIMD_acoshf64x = "";
pub const __DECL_SIMD_acoshf128x = "";
pub const __DECL_SIMD_erf = "";
pub const __DECL_SIMD_erff = "";
pub const __DECL_SIMD_erfl = "";
pub const __DECL_SIMD_erff16 = "";
pub const __DECL_SIMD_erff32 = "";
pub const __DECL_SIMD_erff64 = "";
pub const __DECL_SIMD_erff128 = "";
pub const __DECL_SIMD_erff32x = "";
pub const __DECL_SIMD_erff64x = "";
pub const __DECL_SIMD_erff128x = "";
pub const __DECL_SIMD_tanh = "";
pub const __DECL_SIMD_tanhf = "";
pub const __DECL_SIMD_tanhl = "";
pub const __DECL_SIMD_tanhf16 = "";
pub const __DECL_SIMD_tanhf32 = "";
pub const __DECL_SIMD_tanhf64 = "";
pub const __DECL_SIMD_tanhf128 = "";
pub const __DECL_SIMD_tanhf32x = "";
pub const __DECL_SIMD_tanhf64x = "";
pub const __DECL_SIMD_tanhf128x = "";
pub const __DECL_SIMD_asinh = "";
pub const __DECL_SIMD_asinhf = "";
pub const __DECL_SIMD_asinhl = "";
pub const __DECL_SIMD_asinhf16 = "";
pub const __DECL_SIMD_asinhf32 = "";
pub const __DECL_SIMD_asinhf64 = "";
pub const __DECL_SIMD_asinhf128 = "";
pub const __DECL_SIMD_asinhf32x = "";
pub const __DECL_SIMD_asinhf64x = "";
pub const __DECL_SIMD_asinhf128x = "";
pub const __DECL_SIMD_erfc = "";
pub const __DECL_SIMD_erfcf = "";
pub const __DECL_SIMD_erfcl = "";
pub const __DECL_SIMD_erfcf16 = "";
pub const __DECL_SIMD_erfcf32 = "";
pub const __DECL_SIMD_erfcf64 = "";
pub const __DECL_SIMD_erfcf128 = "";
pub const __DECL_SIMD_erfcf32x = "";
pub const __DECL_SIMD_erfcf64x = "";
pub const __DECL_SIMD_erfcf128x = "";
pub const __DECL_SIMD_tan = "";
pub const __DECL_SIMD_tanf = "";
pub const __DECL_SIMD_tanl = "";
pub const __DECL_SIMD_tanf16 = "";
pub const __DECL_SIMD_tanf32 = "";
pub const __DECL_SIMD_tanf64 = "";
pub const __DECL_SIMD_tanf128 = "";
pub const __DECL_SIMD_tanf32x = "";
pub const __DECL_SIMD_tanf64x = "";
pub const __DECL_SIMD_tanf128x = "";
pub const __DECL_SIMD_sinpi = "";
pub const __DECL_SIMD_sinpif = "";
pub const __DECL_SIMD_sinpil = "";
pub const __DECL_SIMD_sinpif16 = "";
pub const __DECL_SIMD_sinpif32 = "";
pub const __DECL_SIMD_sinpif64 = "";
pub const __DECL_SIMD_sinpif128 = "";
pub const __DECL_SIMD_sinpif32x = "";
pub const __DECL_SIMD_sinpif64x = "";
pub const __DECL_SIMD_sinpif128x = "";
pub const __DECL_SIMD_cospi = "";
pub const __DECL_SIMD_cospif = "";
pub const __DECL_SIMD_cospil = "";
pub const __DECL_SIMD_cospif16 = "";
pub const __DECL_SIMD_cospif32 = "";
pub const __DECL_SIMD_cospif64 = "";
pub const __DECL_SIMD_cospif128 = "";
pub const __DECL_SIMD_cospif32x = "";
pub const __DECL_SIMD_cospif64x = "";
pub const __DECL_SIMD_cospif128x = "";
pub const __DECL_SIMD_tanpi = "";
pub const __DECL_SIMD_tanpif = "";
pub const __DECL_SIMD_tanpil = "";
pub const __DECL_SIMD_tanpif16 = "";
pub const __DECL_SIMD_tanpif32 = "";
pub const __DECL_SIMD_tanpif64 = "";
pub const __DECL_SIMD_tanpif128 = "";
pub const __DECL_SIMD_tanpif32x = "";
pub const __DECL_SIMD_tanpif64x = "";
pub const __DECL_SIMD_tanpif128x = "";
pub const __DECL_SIMD_acospi = "";
pub const __DECL_SIMD_acospif = "";
pub const __DECL_SIMD_acospil = "";
pub const __DECL_SIMD_acospif16 = "";
pub const __DECL_SIMD_acospif32 = "";
pub const __DECL_SIMD_acospif64 = "";
pub const __DECL_SIMD_acospif128 = "";
pub const __DECL_SIMD_acospif32x = "";
pub const __DECL_SIMD_acospif64x = "";
pub const __DECL_SIMD_acospif128x = "";
pub const __DECL_SIMD_asinpi = "";
pub const __DECL_SIMD_asinpif = "";
pub const __DECL_SIMD_asinpil = "";
pub const __DECL_SIMD_asinpif16 = "";
pub const __DECL_SIMD_asinpif32 = "";
pub const __DECL_SIMD_asinpif64 = "";
pub const __DECL_SIMD_asinpif128 = "";
pub const __DECL_SIMD_asinpif32x = "";
pub const __DECL_SIMD_asinpif64x = "";
pub const __DECL_SIMD_asinpif128x = "";
pub const __DECL_SIMD_atanpi = "";
pub const __DECL_SIMD_atanpif = "";
pub const __DECL_SIMD_atanpil = "";
pub const __DECL_SIMD_atanpif16 = "";
pub const __DECL_SIMD_atanpif32 = "";
pub const __DECL_SIMD_atanpif64 = "";
pub const __DECL_SIMD_atanpif128 = "";
pub const __DECL_SIMD_atanpif32x = "";
pub const __DECL_SIMD_atanpif64x = "";
pub const __DECL_SIMD_atanpif128x = "";
pub const __DECL_SIMD_atan2pi = "";
pub const __DECL_SIMD_atan2pif = "";
pub const __DECL_SIMD_atan2pil = "";
pub const __DECL_SIMD_atan2pif16 = "";
pub const __DECL_SIMD_atan2pif32 = "";
pub const __DECL_SIMD_atan2pif64 = "";
pub const __DECL_SIMD_atan2pif128 = "";
pub const __DECL_SIMD_atan2pif32x = "";
pub const __DECL_SIMD_atan2pif64x = "";
pub const __DECL_SIMD_atan2pif128x = "";
pub const _BITS_FLOATN_H = "";
pub const __HAVE_FLOAT128 = @as(c_int, 1);
pub const __HAVE_DISTINCT_FLOAT128 = @as(c_int, 1);
pub const __HAVE_FLOAT64X = @as(c_int, 1);
pub const __HAVE_FLOAT64X_LONG_DOUBLE = @as(c_int, 1);
pub const __f128 = @compileError("unable to translate macro: undefined identifier `f128`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/x86-linux-gnu/bits/floatn.h:72:12
pub const __CFLOAT128 = @compileError("unable to translate: invalid numeric type"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/x86-linux-gnu/bits/floatn.h:86:12
pub const _BITS_FLOATN_COMMON_H = "";
pub const __HAVE_FLOAT16 = @as(c_int, 0);
pub const __HAVE_FLOAT32 = @as(c_int, 1);
pub const __HAVE_FLOAT64 = @as(c_int, 1);
pub const __HAVE_FLOAT32X = @as(c_int, 1);
pub const __HAVE_FLOAT128X = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT16 = __HAVE_FLOAT16;
pub const __HAVE_DISTINCT_FLOAT32 = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT64 = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT32X = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT64X = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT128X = __HAVE_FLOAT128X;
pub const __HAVE_FLOAT128_UNLIKE_LDBL = (__HAVE_DISTINCT_FLOAT128 != 0) and (__LDBL_MANT_DIG__ != @as(c_int, 113));
pub const __HAVE_FLOATN_NOT_TYPEDEF = @as(c_int, 1);
pub const __f32 = @compileError("unable to translate macro: undefined identifier `f32`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/floatn-common.h:93:12
pub const __f64 = @compileError("unable to translate macro: undefined identifier `f64`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/floatn-common.h:105:12
pub const __f32x = @compileError("unable to translate macro: undefined identifier `f32x`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/floatn-common.h:113:12
pub const __f64x = @compileError("unable to translate macro: undefined identifier `f64x`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/floatn-common.h:125:12
pub const __CFLOAT32 = @compileError("unable to translate: invalid numeric type"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/floatn-common.h:151:12
pub const __CFLOAT64 = @compileError("unable to translate: invalid numeric type"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/floatn-common.h:163:12
pub const __CFLOAT32X = @compileError("unable to translate: invalid numeric type"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/floatn-common.h:171:12
pub const __CFLOAT64X = @compileError("unable to translate: invalid numeric type"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/floatn-common.h:183:12
pub const HUGE_VAL = @compileError("unable to translate macro: undefined identifier `__builtin_huge_val`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:49:10
pub const HUGE_VALF = __builtin.huge_valf();
pub const HUGE_VALL = @compileError("unable to translate macro: undefined identifier `__builtin_huge_vall`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:61:11
pub const INFINITY = __builtin.inff();
pub const NAN = __builtin.nanf("");
pub const __GLIBC_FLT_EVAL_METHOD = __FLT_EVAL_METHOD__;
pub const __FP_LOGB0_IS_MIN = @as(c_int, 1);
pub const __FP_LOGBNAN_IS_MIN = @as(c_int, 1);
pub const FP_ILOGB0 = -__helpers.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const FP_ILOGBNAN = -__helpers.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const __SIMD_DECL = @compileError("unable to translate macro: undefined identifier `__DECL_SIMD_`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/mathcalls-macros.h:19:9
pub const __MATHCALL_VEC = @compileError("unable to translate macro: undefined identifier `__MATH_PRECNAME`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/mathcalls-macros.h:21:9
pub const __MATHDECL_VEC = @compileError("unable to translate macro: undefined identifier `__MATH_PRECNAME`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/mathcalls-macros.h:25:9
pub const __MATHCALLX = @compileError("unable to translate macro: undefined identifier `_Mdouble_`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/mathcalls-macros.h:34:9
pub const __MATHDECLX = @compileError("unable to translate macro: undefined identifier `__MATHDECL_1`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/mathcalls-macros.h:36:9
pub const __MATHREDIR = @compileError("unable to translate macro: undefined identifier `__MATH_PRECNAME`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/bits/mathcalls-macros.h:47:9
pub const __MATH_DECLARE_LDOUBLE = @as(c_int, 1);
pub const __MATH_TG_F32 = @compileError("unable to translate macro: undefined identifier `f`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:1021:12
pub const __MATH_TG_F64X = @compileError("unable to translate macro: undefined identifier `l`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:1027:13
pub const __MATH_TG = @compileError("unable to translate macro: undefined identifier `f`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:1034:11
pub const fpclassify = @compileError("unable to translate macro: undefined identifier `__builtin_fpclassify`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:1104:11
pub inline fn signbit(x: anytype) @TypeOf(__builtin.signbit(x)) {
    _ = &x;
    return __builtin.signbit(x);
}
pub const isfinite = @compileError("unable to translate macro: undefined identifier `__builtin_isfinite`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:1131:11
pub const isnormal = @compileError("unable to translate macro: undefined identifier `__builtin_isnormal`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:1139:11
pub const MATH_ERRNO = @as(c_int, 1);
pub const MATH_ERREXCEPT = @as(c_int, 2);
pub const math_errhandling = MATH_ERRNO | MATH_ERREXCEPT;
pub const M_E = @as(f64, 2.7182818284590452354);
pub const M_LOG2E = @as(f64, 1.4426950408889634074);
pub const M_LOG10E = @as(f64, 0.43429448190325182765);
pub const M_LN2 = @as(f64, 0.69314718055994530942);
pub const M_LN10 = @as(f64, 2.30258509299404568402);
pub const M_PI = @as(f64, 3.14159265358979323846);
pub const M_PI_2 = @as(f64, 1.57079632679489661923);
pub const M_PI_4 = @as(f64, 0.78539816339744830962);
pub const M_1_PI = @as(f64, 0.31830988618379067154);
pub const M_2_PI = @as(f64, 0.63661977236758134308);
pub const M_2_SQRTPI = @as(f64, 1.12837916709551257390);
pub const M_SQRT2 = @as(f64, 1.41421356237309504880);
pub const M_SQRT1_2 = @as(f64, 0.70710678118654752440);
pub const isgreater = @compileError("unable to translate macro: undefined identifier `__builtin_isgreater`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:1443:11
pub const isgreaterequal = @compileError("unable to translate macro: undefined identifier `__builtin_isgreaterequal`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:1444:11
pub const isless = @compileError("unable to translate macro: undefined identifier `__builtin_isless`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:1445:11
pub const islessequal = @compileError("unable to translate macro: undefined identifier `__builtin_islessequal`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:1446:11
pub const islessgreater = @compileError("unable to translate macro: undefined identifier `__builtin_islessgreater`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:1447:11
pub const isunordered = @compileError("unable to translate macro: undefined identifier `__builtin_isunordered`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/libc/include/generic-glibc/math.h:1448:11
/// https://en.wikipedia.org/wiki/Pi
pub const B3_PI = @as(f32, 3.14159265359);
/// Convenience macro to convert from degrees to radians.
pub const B3_DEG_TO_RAD = @as(f32, 0.01745329251);
/// Convenience macro to convert from radians to degrees.
pub const B3_RAD_TO_DEG = @as(f32, 57.2957795131);
/// Minimum scale used for scaling collision meshes, etc.
pub const B3_MIN_SCALE = @as(f32, 0.01);
pub const B3_HUGE = @as(f32, 1.0e5) * b3GetLengthUnitsPerMeter();
/// Maximum parallel workers. Used for some fixed size arrays.
pub const B3_MAX_WORKERS = @as(c_int, 32);
/// Maximum number of tasks queued per world step. b3EnqueueTaskCallback will never be called
/// more than this per world step. This is related to B3_MAX_WORKERS. With 32 workers,
/// the maximum observed task count is 130. This allows an external task system to use a fixed
/// size array for Box3D task, which may help with creating stable user task pointers.
pub const B3_MAX_TASKS = @as(c_int, 256);
pub const B3_GRAPH_COLOR_COUNT = @as(c_int, 24);
pub const B3_CONTACT_MANIFOLD_COUNT_BUCKETS = @as(c_int, 8);
pub const B3_LINEAR_SLOP = @as(f32, 0.005) * b3GetLengthUnitsPerMeter();
/// The minimum length of a capsules. Very short capsules should be created as spheres
/// to avoid numerical problems.
pub const B3_MIN_CAPSULE_LENGTH = B3_LINEAR_SLOP;
/// Minimum contact point friction weight, lower bound for speculative points. Made small
/// enough to be washed away by weights that hit 1.
pub const B3_MIN_FRICTION_WEIGHT = @as(f32, 1e-10);
/// The distance between shapes where they are considered overlapped. This is needed
/// because GJK may return small positive values for overlapped shapes in degenerate
/// configurations.
pub const B3_OVERLAP_SLOP = @as(f32, 0.1) * B3_LINEAR_SLOP;
/// Maximum number of simultaneous worlds that can be allocated
pub const B3_MAX_WORLDS = @as(c_int, 128);
/// The maximum rotation of a body per time step. This limit is very large and is used
/// to prevent numerical problems. You shouldn't need to adjust this.
/// @warning increasing this to 0.5f * B3_PI or greater will break continuous collision.
pub const B3_MAX_ROTATION = @as(f32, 0.25) * B3_PI;
/// @warning modifying this can have a significant impact on performance and stability
pub const B3_SPECULATIVE_DISTANCE = @as(f32, 4.0) * B3_LINEAR_SLOP;
/// The rest offset is used for mesh contact to reduce ghost collisions and assist with CCD.
/// The rest offset adjusts the contact point separation value, making the solver push the shapes
/// apart by this distance.
/// Must be at least B3_LINEAR_SLOP and less than B3_SPECULATIVE_DISTANCE.
pub const B3_MESH_REST_OFFSET = @as(f32, 1.0) * B3_LINEAR_SLOP;
/// The default contact recycling distance.
pub const B3_CONTACT_RECYCLE_DISTANCE = @as(f32, 10.0) * B3_LINEAR_SLOP;
/// The default contact recycling world angle threshold. For performance this value
/// is cos(angle/2)^2. This value corresponds to 10 degrees.
pub const B3_CONTACT_RECYCLE_ANGULAR_DISTANCE = @as(f32, 0.99240388);
pub const B3_MAX_AABB_MARGIN = @as(f32, 0.05) * b3GetLengthUnitsPerMeter();
/// Per-shape AABB margin is a fraction of the shape extent (capped by B3_MAX_AABB_MARGIN).
/// Small shapes get small margins; large shapes are clamped to the cap.
pub const B3_AABB_MARGIN_FRACTION = @as(f32, 0.125);
/// The time that a body must be still before it will go to sleep. In seconds.
pub const B3_TIME_TO_SLEEP = @as(f32, 0.5);
/// The maximum number of contact points between two touching shapes.
pub const B3_MAX_MANIFOLD_POINTS = @as(c_int, 4);
/// The number of iterations for gyroscopic torques.
pub const B3_GYROSCOPIC_ITERATIONS = @as(c_int, 1);
/// The maximum number of convex hull vertices. This is fixed for performance reasons.
pub const B3_MAX_HULL_VERTICES = @as(c_int, 128);
/// The maximum number of convex hull faces.
pub const B3_MAX_HULL_FACES = @as(c_int, 128);
/// The maximum number of convex hull edges. Full edges, not half-edges.
pub const B3_MAX_HULL_EDGES = @as(c_int, 128);
/// Relative tolerance used to determine if two edges are parallel.
pub const B3_PARALLEL_EDGE_TOL = @as(f32, 0.005);
/// The maximum number points to use for shape cast proxies (swept point cloud).
pub const B3_MAX_SHAPE_CAST_POINTS = B3_MAX_HULL_VERTICES;
/// These generous limits allow for easy hashing. See b3ShapePairKey.
pub const B3_SHAPE_POWER = @as(c_int, 22);
pub const B3_CHILD_POWER = @as(c_int, 64) - (@as(c_int, 2) * B3_SHAPE_POWER);
pub const B3_MAX_SHAPES = @as(c_int, 1) << B3_SHAPE_POWER;
pub const B3_MAX_CHILD_SHAPES = @as(c_int, 1) << B3_CHILD_POWER;
/// Increase this if your application needs more accurate restitution. Doing so will
/// slow down the simulation. Must be 1 or more.
pub const B3_RESTITUTION_ITERATIONS = @as(c_int, 1);
/// A null id. Works for any id type.
pub const B3_NULL_ID = @compileError("unable to translate C expr: unexpected token '{'"); // box3d/include/box3d/id.h:83:10
/// This macro bridges C and C++ inline functions. C++ has the one definition rule that C lacks.
pub const B3_ID_INLINE = @compileError("unable to translate C expr: unexpected token 'static'"); // box3d/include/box3d/id.h:86:10
/// Macro to determine if any id is null.
pub inline fn B3_IS_NULL(id: anytype) @TypeOf(id.index1 == @as(c_int, 0)) {
    _ = &id;
    return id.index1 == @as(c_int, 0);
}
/// Macro to determine if any id is non-null.
pub inline fn B3_IS_NON_NULL(id: anytype) @TypeOf(id.index1 != @as(c_int, 0)) {
    _ = &id;
    return id.index1 != @as(c_int, 0);
}
/// Compare two ids for equality. Doesn't work for b3WorldId. Don't mix types.
pub inline fn B3_ID_EQUALS(id1: anytype, id2: anytype) @TypeOf(((id1.index1 == id2.index1) and (id1.world0 == id2.world0)) and (id1.generation == id2.generation)) {
    _ = &id1;
    _ = &id2;
    return ((id1.index1 == id2.index1) and (id1.world0 == id2.world0)) and (id1.generation == id2.generation);
}
pub const B3_DEFAULT_CATEGORY_BITS = UINT64_MAX;
pub const B3_DEFAULT_MASK_BITS = UINT64_MAX;
/// Dynamic tree version for compatibility testing.
pub const B3_DYNAMIC_TREE_VERSION = @as(c_ulonglong, 0x93EDAF889FD30B4A);
/// 64-bit hull version. Useful for validating serialized data.
pub const B3_HULL_VERSION = @as(c_ulonglong, 0xDA5150191B994C01);
/// 64-bit mesh version. Useful for validating serialized data.
pub const B3_MESH_VERSION = @as(c_ulonglong, 0xABD11AB62A6E886D);
/// This material index is used to designate holes in a height field.
pub const B3_HEIGHT_FIELD_HOLE = @as(c_int, 0xFF);
/// 64-bit height-field version. Useful for validating serialized data.
pub const B3_HEIGHT_FIELD_VERSION = @as(c_ulonglong, 0x8B18CBD138A6BC84);
/// The baked compound version depends on the tree, mesh, and hull versions.
pub const B3_COMPOUND_VERSION = ((@as(c_ulonglong, 0xB11DCE70FAD5622B) ^ B3_DYNAMIC_TREE_VERSION) ^ B3_MESH_VERSION) ^ B3_HULL_VERSION;
/// Meshes used in compounds have limited space for materials. If you have
/// a mesh with many materials, you can use it outside of the compound.
pub const B3_MAX_COMPOUND_MESH_MATERIALS = @as(c_int, 4);
pub const __STDC_VERSION_STDDEF_H__ = @as(c_long, 202311);
pub const NULL = __helpers.cast(?*anyopaque, @as(c_int, 0));
pub const offsetof = @compileError("unable to translate macro: undefined identifier `__builtin_offsetof`"); // /home/dylan/.local/opt/zig-x86_64-linux-0.17.0-dev.1622+2b242157b/lib/compiler/aro/include/stddef.h:18:9
