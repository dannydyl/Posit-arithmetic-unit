#include "op2.h"
#include "util.h"
#include <stdio.h>

static struct unpacked_t add(struct unpacked_t a, struct unpacked_t b, bool neg)
{
    struct unpacked_t r;
    // printf("before hidden bit a.frac: %lu\n", a.frac);
    // printf("before hidden bit b.frac: %lu\n", b.frac);
    POSIT_LUTYPE afrac = HIDDEN_BIT(a.frac);
    POSIT_LUTYPE bfrac = HIDDEN_BIT(b.frac);
    POSIT_LUTYPE frac;
    // printf("after hidden bit a.frac: %lu\n", afrac);
    // printf("after hidden bit b.frac: %lu\n", bfrac);

    if (a.exp > b.exp) {
        r.exp = a.exp;
        bfrac = RSHIFT(bfrac, a.exp - b.exp);
        // printf("a is greater than b\n");
    } else {
        r.exp = b.exp;
        afrac = RSHIFT(afrac, b.exp - a.exp);
        // printf("b is greater than a\n");
    }
    // printf("afrac after shift: %lu\n", afrac);
    // printf("bfrac after shift: %lu\n", bfrac);
    frac = afrac + bfrac;
    // printf("gfdsgfdsgdfrac: %lu\n", frac);
    // printf("rshifted frac: %lu\n", RSHIFT(frac, POSIT_WIDTH));
    if (RSHIFT(frac, POSIT_WIDTH) != 0) {
        // printf("\nOverflow detected\n");
        r.exp++;
        frac = RSHIFT(frac, 1);
    }
    // printf("result frac: %lu\n", frac);
    r.neg = neg;
    r.frac = LSHIFT(frac, 1);
    // printf("r.frac: %lu\n", r.frac);
    return r;
}

static struct unpacked_t sub(struct unpacked_t a, struct unpacked_t b, bool neg)
{
    struct unpacked_t r;
    POSIT_UTYPE afrac = HIDDEN_BIT(a.frac);
    POSIT_UTYPE bfrac = HIDDEN_BIT(b.frac);
    POSIT_UTYPE frac;

    if (a.exp > b.exp || (a.exp == b.exp && a.frac > b.frac)) {
        r.exp = a.exp;
        bfrac = RSHIFT(bfrac, a.exp - b.exp);
        frac = afrac - bfrac;
    } else {
        neg = !neg;
        r.exp = b.exp;
        afrac = RSHIFT(afrac, b.exp - a.exp);
        frac = bfrac - afrac;
    }

    r.neg = neg;
    r.exp -= CLZ(frac);
    r.frac = LSHIFT(frac, CLZ(frac) + 1);

    return r;
}

struct unpacked_t op2_mul(struct unpacked_t a, struct unpacked_t b)
{
    struct unpacked_t r;

    POSIT_LUTYPE afrac = HIDDEN_BIT(a.frac);
    POSIT_LUTYPE bfrac = HIDDEN_BIT(b.frac);
    POSIT_UTYPE frac = RSHIFT(afrac * bfrac, POSIT_WIDTH);
    POSIT_STYPE exp = a.exp + b.exp + 1;

    if ((frac & POSIT_MSB) == 0) {
        exp--;
        frac = LSHIFT(frac, 1);
    }

    r.neg = a.neg ^ b.neg;
    r.exp = exp;
    r.frac = LSHIFT(frac, 1);

    return r;
}

struct unpacked_t op2_div(struct unpacked_t a, struct unpacked_t b)
{
    struct unpacked_t r;

    POSIT_LUTYPE afrac = HIDDEN_BIT(a.frac);
    POSIT_LUTYPE bfrac = HIDDEN_BIT(b.frac);
    POSIT_STYPE exp = a.exp - b.exp;

    if (afrac < bfrac) {
        exp--;
        bfrac = RSHIFT(bfrac, 1);
    }

    r.neg = a.neg ^ b.neg;
    r.exp = exp;
    r.frac = LSHIFT(afrac, POSIT_WIDTH) / bfrac;

    return r;
}

struct unpacked_t op2_add(struct unpacked_t a, struct unpacked_t b)
{
    if (a.neg == b.neg) {
        return add(a, b, a.neg);
    } else {
        return sub(a, b, a.neg);
    }
}

struct unpacked_t op2_sub(struct unpacked_t a, struct unpacked_t b)
{
    if (a.neg == b.neg) {
        return sub(a, b, a.neg);
    } else {
        return add(a, b, a.neg);
    }
}
