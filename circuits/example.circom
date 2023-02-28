pragma circom 2.0.0;

/*
 * Decomposes `in` into `b` bits, given by `bits`.
 * Least significant bit in `bits[0]`.
 * Enforces that `in` is at most `b` bits long.
 */
template Num2Bits(b) {
    signal input in;
    signal output bits[b];

    // First, compute the bit values
    for (var i = 0; i < b; i++) {
        // Use `<--` to assign to a signal without constraining it.
        // While our constraints can only use multiplication/addition, our
        // assignments can use any operation.
        bits[i] <-- (in >> i) & 1;
    }

    // Now, contrain each bit to be 0 or 1.
    for (var i = 0; i < b; i++) {
        // Use `===` to enforce a rank-1 constraint (R1C) on signals.
        bits[i] * (1 - bits[i]) === 0;
     // ^--A--^   ^-----B-----^     C
     //
     // The linear combinations A, B, and C in this R1C.
    }

    // Now, construct a sum of all the bits.
    // Note that var is a linear combination of signals since the `(2 ** i)` terms are constants.
    var sum_of_bits = 0;
    for (var i = 0; i < b; i++) {
        sum_of_bits += (2 ** i) * bits[i];
    }
    // Constrain that `sum` is equal to the input `in`.
    sum_of_bits === in;
}

// Now we look at `SmallOdd`, a circuit which features:
//
//    * the use of components, or sub-circuits
//    * the `<==` operator, which combines `<--` and `===`.

/*
 * Enforces that `in` is an odd number less than 2 ** `b`.
 */
template SmallOdd(b) {
    signal input in;

    // Declare and intialize a sub-circuit;
    component binaryDecomposition = Num2Bits(b);

    // Use `<==` to **assign** and **constrain** simultaneously.
    binaryDecomposition.in <== in;

    // Constrain the least significant bit to be 1.
    binaryDecomposition.bits[0] === 1;
}

// Next we look at `SmallOddFactorization`, a circuit which features:
//
//    * arrays of components
//    * using helper (witness) signals to express multiple multiplications
//       * (or any iterator general computation)

/*
 * Enforces the factorization of `product` into `n` odd factors that are each
 * less than 2 ** `b`.
 */
template SmallOddFactorization(n, b) {
    signal input product;
    signal input factors[n];

    // Constrain each factor to be small and odd.
    // We're going to need `n` subcircuits for small-odd-ness.
    component smallOdd[n];
    for (var i = 0; i < n; i++) {
        smallOdd[i] = SmallOdd(b);
        smallOdd[i].in <== factors[i];
    }

    // Now constrain the factors to multiply to the product. Since there are
    // many multiplications, we introduce helper signals to split the
    // multiplications up into R1Cs.
    signal partialProducts[n + 1];
    partialProducts[0] <== 1;
    for (var i = 0; i < n; i++) {
        partialProducts[i + 1] <== partialProducts[i] * factors[i];
    }
    product === partialProducts[n];
}

// Finally, we set the `main` circuit for this file, which is the circuit that
// `circom` will synthesize.
component main {public [product]} = SmallOddFactorization(3, 8);
