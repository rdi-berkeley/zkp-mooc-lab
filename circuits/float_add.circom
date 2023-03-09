pragma circom 2.0.0;

/////////////////////////////////////////////////////////////////////////////////////
/////////////////////// Templates from the circomlib ////////////////////////////////
////////////////// Copy-pasted here for easy reference //////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////

/*
 * Outputs `a` AND `b`
 */
template AND() {
    signal input a;
    signal input b;
    signal output out;

    out <== a*b;
}

/*
 * Outputs `a` OR `b`
 */
template OR() {
    signal input a;
    signal input b;
    signal output out;

    out <== a + b - a*b;
}

/*
 * `out` = `cond` ? `L` : `R`
 */
template IfThenElse() {
    signal input cond;
    signal input L;
    signal input R;
    signal output out;

    out <== cond * (L - R) + R;
}

/*
 * (`outL`, `outR`) = `sel` ? (`R`, `L`) : (`L`, `R`)
 */
template Switcher() {
    signal input sel;
    signal input L;
    signal input R;
    signal output outL;
    signal output outR;

    signal aux;

    aux <== (R-L)*sel;
    outL <==  aux + L;
    outR <== -aux + R;
}

/*
 * Decomposes `in` into `b` bits, given by `bits`.
 * Least significant bit in `bits[0]`.
 * Enforces that `in` is at most `b` bits long.
 */
template Num2Bits(b) {
    signal input in;
    signal output bits[b];

    for (var i = 0; i < b; i++) {
        bits[i] <-- (in >> i) & 1;
        bits[i] * (1 - bits[i]) === 0;
    }
    var sum_of_bits = 0;
    for (var i = 0; i < b; i++) {
        sum_of_bits += (2 ** i) * bits[i];
    }
    sum_of_bits === in;
}

/*
 * Reconstructs `out` from `b` bits, given by `bits`.
 * Least significant bit in `bits[0]`.
 */
template Bits2Num(b) {
    signal input bits[b];
    signal output out;
    var lc = 0;

    for (var i = 0; i < b; i++) {
        lc += (bits[i] * (1 << i));
    }
    out <== lc;
}

/*
 * Checks if `in` is zero and returns the output in `out`.
 */
template IsZero() {
    signal input in;
    signal output out;

    signal inv;

    inv <-- in!=0 ? 1/in : 0;

    out <== -in*inv +1;
    in*out === 0;
}

/*
 * Checks if `in[0]` == `in[1]` and returns the output in `out`.
 */
template IsEqual() {
    signal input in[2];
    signal output out;

    component isz = IsZero();

    in[1] - in[0] ==> isz.in;

    isz.out ==> out;
}

/*
 * Checks if `in[0]` < `in[1]` and returns the output in `out`.
 */
template LessThan(n) {
    assert(n <= 252);
    signal input in[2];
    signal output out;

    component n2b = Num2Bits(n+1);

    n2b.in <== in[0]+ (1<<n) - in[1];

    out <== 1-n2b.bits[n];
}

/////////////////////////////////////////////////////////////////////////////////////
///////////////////////// Templates for this lab ////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////

/*
 * Outputs `out` = 1 if `in` is at most `b` bits long, and 0 otherwise.
 */
template CheckBitLength(b) {
    signal input in;
    signal output out;
    signal bits[b];

    for (var i = 0; i < b; i++) {
        bits[i] <-- (in >> i) & 1;
        bits[i] * (1 - bits[i]) === 0;
    }
    var sum_of_bits = 0;
    for (var i = 0; i < b; i++) {
        sum_of_bits += (2 ** i) * bits[i];
    }
    component ise = IsEqual();
    ise.in[0] <== sum_of_bits;
    ise.in[1] <== in;

    out <== ise.out;
}

/*
 * Enforces the well-formedness of an exponent-mantissa pair (e, m), which is defined as follows:
 * if `e` is zero, then `m` must be zero
 * else, `e` must be at most `k` bits long, and `m` must be in the range [2^p, 2^p+1)
 */
template CheckWellFormedness(k, p) {
    signal input e;
    signal input m;

    // check if `e` is zero
    component is_e_zero = IsZero();
    is_e_zero.in <== e;

    // Case I: `e` is zero
    //// `m` must be zero
    component is_m_zero = IsZero();
    is_m_zero.in <== m;

    // Case II: `e` is nonzero
    //// `e` is `k` bits
    component check_e_bits = CheckBitLength(k);
    check_e_bits.in <== e;
    //// `m` is `p`+1 bits with the MSB equal to 1
    //// equivalent to check `m` - 2^`p` is in `p` bits
    component check_m_bits = CheckBitLength(p);
    check_m_bits.in <== m - (1 << p);

    // choose the right checks based on `is_e_zero`
    component if_else = IfThenElse();
    if_else.cond <== is_e_zero.out;
    if_else.L <== is_m_zero.out;
    //// check_m_bits.out * check_e_bits.out is equivalent to check_m_bits.out AND check_e_bits.out
    if_else.R <== check_m_bits.out * check_e_bits.out;

    // assert that those checks passed
    if_else.out === 1;
}

/*
 * Right-shifts `x` by `shift` bits to output `y`, where `shift` is a public circuit parameter.
 */
template RightShift(shift) {
    signal input x;
    signal output y;

    // TODO
    y <-- x >> shift;
}

/*
 * Rounds the input floating-point number and checks to ensure that rounding does not make the mantissa unnormalized.
 * Rounding is necessary to prevent the bitlength of the mantissa from growing with each successive operation.
 * The input is a normalized floating-point number (e, m) with precision `P`, where `e` is a `k`-bit exponent and `m` is a `P`+1-bit mantissa.
 * The output is a normalized floating-point number (e_out, m_out) representing the same value with a lower precision `p`.
 */
template RoundAndCheck(k, p, P) {
    signal input e;
    signal input m;
    signal output e_out;
    signal output m_out;
    assert(P > p);

    // check if no overflow occurs
    component if_no_overflow = LessThan(P+1);
    if_no_overflow.in[0] <== m;
    if_no_overflow.in[1] <== (1 << (P+1)) - (1 << (P-p-1));
    signal no_overflow <== if_no_overflow.out;

    var round_amt = P-p;
    // Case I: no overflow
    // compute (m + 2^{round_amt-1}) >> round_amt
    var m_prime = m + (1 << (round_amt-1));
    component right_shift = RightShift(round_amt);
    right_shift.x <== m_prime;
    var m_out_1 = right_shift.y;
    var e_out_1 = e;

    // Case II: overflow
    var e_out_2 = e + 1;
    var m_out_2 = (1 << p);

    // select right output based on no_overflow
    component if_else[2];
    for (var i = 0; i < 2; i++) {
        if_else[i] = IfThenElse();
        if_else[i].cond <== no_overflow;
    }
    if_else[0].L <== e_out_1;
    if_else[0].R <== e_out_2;
    if_else[1].L <== m_out_1;
    if_else[1].R <== m_out_2;
    e_out <== if_else[0].out;
    m_out <== if_else[1].out;
}

/*
 * Left-shifts `x` by `shift` bits to output `y`.
 * Enforces 0 <= `shift` < `shift_bound`.
 * If `skip_checks` = 1, then we don't care about the output and the `shift_bound` constraint is not enforced.
 */
template LeftShift(shift_bound) {
    signal input x;
    signal input shift;
    signal input skip_checks;
    signal output y;

    y <-- x << shift;
    
    component if_no_overflow = LessThan(25);
    if_no_overflow.in[0] <== shift;
    if_no_overflow.in[1] <== shift_bound;

    component or = OR();
    or.a <== skip_checks;
    or.b <== if_no_overflow.out;
    or.out === 1;
}

/*
 * Find the Most-Significant Non-Zero Bit (MSNZB) of `in`, where `in` is assumed to be non-zero value of `b` bits.
 * Outputs the MSNZB as a one-hot vector `one_hot` of `b` bits, where `one_hot`[i] = 1 if MSNZB(`in`) = i and 0 otherwise.
 * The MSNZB is output as a one-hot vector to reduce the number of constraints in the subsequent `Normalize` template.
 * Enforces that `in` is non-zero as MSNZB(0) is undefined.
 * If `skip_checks` = 1, then we don't care about the output and the non-zero constraint is not enforced.
 */
template MSNZB(b) {
    signal input in;
    signal input skip_checks;
    signal output one_hot[b];

    // TODO
    component lt1[b];
    component lt2[b];
    for (var i = 0; i < b; i++) {
        lt1[i] = LessThan(b);
        lt2[i] = LessThan(b);
        lt1[i].in[0] <== in;
        lt1[i].in[1] <== 1 << (i + 1);
        lt2[i].in[0] <== in;
        lt2[i].in[1] <== 1 << i;
        one_hot[i] <== (1 - lt2[i].out) * lt1[i].out;
    }
    component or = OR();
    or.a <== skip_checks;
    
    component isz = IsZero();
    isz.in <== in;
    or.b <== 1 - isz.out;
    1 === or.out;
}

/*
 * Normalizes the input floating-point number.
 * The input is a floating-point number with a `k`-bit exponent `e` and a `P`+1-bit *unnormalized* mantissa `m` with precision `p`, where `m` is assumed to be non-zero.
 * The output is a floating-point number representing the same value with exponent `e_out` and a *normalized* mantissa `m_out` of `P`+1-bits and precision `P`.
 * Enforces that `m` is non-zero as a zero-value can not be normalized.
 * If `skip_checks` = 1, then we don't care about the output and the non-zero constraint is not enforced.
 */
template Normalize(k, p, P) {
    signal input e;
    signal input m;
    signal input skip_checks;
    signal output e_out;
    signal output m_out;
    assert(P > p);

    component isz = IsZero();
    isz.in <== m;
    
    component or = OR();
    or.a <== 1 - isz.out;
    or.b <== skip_checks;
    or.out === 1;

    component msnzb = MSNZB(P+1);
    msnzb.in <== m;
    msnzb.skip_checks <== skip_checks;

    var el = 0;

    for (var i=1; i<=P; i++) {
        el += (i + 1) * msnzb.one_hot[i];
    }
    
    el--;
    component ls = LeftShift(k);
    ls.x <== m;
    ls.shift <== P - el;
    ls.skip_checks <== skip_checks;
    m_out <== ls.y;
    e_out <== e + el - p;
}

/*
 * Adds two floating-point numbers.
 * The inputs are normalized floating-point numbers with `k`-bit exponents `e` and `p`+1-bit mantissas `m` with scale `p`.
 * Does not assume that the inputs are well-formed and makes appropriate checks for the same.
 * The output is a normalized floating-point number with exponent `e_out` and mantissa `m_out` of `p`+1-bits and scale `p`.
 * Enforces that inputs are well-formed.
 */
template FloatAdd(k, p) {
    signal input e[2];
    signal input m[2];
    signal output e_out;
    signal output m_out;

    // TODO

    component check_well_formedness1 = CheckWellFormedness(k, p);
    check_well_formedness1.e <== e[0];
    check_well_formedness1.m <== m[0];

    component check_well_formedness2 = CheckWellFormedness(k, p);
    check_well_formedness2.e <== e[1];
    check_well_formedness2.m <== m[1];

    component ls1 = LeftShift(0);
    component ls2 = LeftShift(0);
    ls1.x <== e[0];
    ls1.shift <== p+1;
    ls1.skip_checks <== 1;

    ls2.x <== e[1];
    ls2.shift <== p+1;
    ls2.skip_checks <== 1;

    signal mgn_1 <== ls1.y + m[0];
    signal mgn_2 <== ls2.y + m[1];
    
    component lt = LessThan(100);
    lt.in[0] <== mgn_2;
    lt.in[1] <== mgn_1;
    signal alpha_e;
    signal beta_e;
    signal alpha_m;
    signal beta_m;

    component switcher1 = Switcher();
    component switcher2 = Switcher();
    switcher1.sel <== lt.out;
    switcher1.L <== e[0];
    switcher1.R <== e[1];
    switcher1.outL ==> beta_e;
    switcher1.outR ==> alpha_e;

    switcher2.sel <== lt.out;
    switcher2.L <== m[0];
    switcher2.R <== m[1];
    switcher2.outL ==> beta_m;
    switcher2.outR ==> alpha_m;

    signal diff <== alpha_e - beta_e;

    component isz = IsZero();
    isz.in <== alpha_e;

    component lt1 = LessThan(k);
    lt1.in[0] <== p + 1;
    lt1.in[1] <== diff;

    component or = OR();
    or.a <== isz.out;
    or.b <== lt1.out;

    component ls3 = LeftShift(0);
    ls3.x <== alpha_m;
    ls3.shift <== diff;
    ls3.skip_checks <== 1;

    component normalize = Normalize(k, p, 2*p+1);
    component if_then_else3 = IfThenElse();
    if_then_else3.cond <== or.out;
    if_then_else3.L <== 0;
    if_then_else3.R <== beta_e;
    if_then_else3.out ==> normalize.e;
    component if_then_else4 = IfThenElse();
    if_then_else4.cond <== or.out;
    if_then_else4.L <== 0;
    if_then_else4.R <== ls3.y + beta_m;
    if_then_else4.out ==> normalize.m;
    normalize.skip_checks <== 1;

    component round_nearest_and_check = RoundAndCheck(k, p, 2*p+1);
    round_nearest_and_check.e <== normalize.e_out;
    round_nearest_and_check.m <== normalize.m_out;

    component if_then_else1 = IfThenElse();
    component if_then_else2 = IfThenElse();
    if_then_else1.cond <== or.out;
    if_then_else2.cond <== or.out;
    if_then_else1.L <== alpha_e;
    if_then_else1.R <== round_nearest_and_check.e_out;
    if_then_else1.out ==> e_out;

    if_then_else2.L <== alpha_m;
    if_then_else2.R <== round_nearest_and_check.m_out;
    if_then_else2.out ==> m_out;

}
