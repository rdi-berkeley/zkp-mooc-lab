import random

''' Basics of floating-point representation
    A floating-point number for the purposes of this exercise is a pair (e, m), where `e` is a `k`-bit exponent and `m` is a `p`+1-bit mantissa. `p` is called the precision of the mantissa/number.
    The exponent `e` represents values in the range [-2^{k-1}, 2^{k-1}), but is stored as a non-negative `k`-bit integer by adding a constant `bias` = 2^{k-1} to it.
    The mantissa `m` lies in the range [2^p, 2^p+1), i.e., its `p`-th bit is always set, and it represents the following real value: m/2^p.
    The only exception to the mantissa range is the value 0, in which case both the exponent and mantissa are 0.
    Overall, the value represented by a floating-point number is: m/2^p * 2^{e-bias}.
'''

''' Enforces the well-formedness of an exponent-mantissa pair (e, m)
    if `e` is zero, then `m` must be zero
    else, `e` must be at most `k` bits long, and `m` must be normalized, i.e., lie in the range [2^p, 2^p+1)
'''
def check_well_formedness(k, p, e, m):
    if e == 0:
        assert( m == 0 )
    else:
        exponent_bitcheck = (e.bit_length() <= k)
        ''' To check if mantissa is in the range [2^p, 2^(p+1))
            We can instead check if mantissa - 2^p is in the range [0, 2^p)
        '''
        tmp = m - 2 ** p
        mantissa_bitcheck = tmp.bit_length() <= p

        assert( exponent_bitcheck and mantissa_bitcheck )

''' Find the Most-Significant Non-Zero Bit (MSNZB) of `inp`, where `inp` is assumed to be non-zero value of `b` bits.
    Note that `ell` is the MSNZB of `inp` if and only if 2^ell <= inp < 2^{ell + 1}.
'''
def msnzb(inp, b):
    assert(inp != 0 and inp < (2 ** b))
    for i in range(b):
        if (2 ** i) <= inp and inp < (2 ** (i + 1)):
            return i

''' Normalizes the input floating-point number.
    The input is a floating-point number with a `k`-bit exponent `e` and a `P`+1-bit *unnormalized* mantissa `m` with precision `p` (i.e., m does not necessarily lie in [2^p, 2^{p+1}) ), where `m` is assumed to be non-zero.
    The output is a floating-point number representing the exact same value with exponent `e_out` and a `P`+1-bit *normalized* mantissa `m_out` with precision `P` (i.e., m_out lies in [2^P, 2^{P+1}) ).
'''
def normalize(k, p, P, e, m):
    assert(P > p and m != 0)
    ''' Let ell be the MSNZB of m. Recall that m is a P+1-bit number with precision p.
        We want to make the mantissa normalized, i.e., bring it to the range [2^P, 2^(P+1)), by shifting it left by P-ell bits.
        Consequently, we need to decrement the exponent by P-ell.
        At the same time, we are also increasing precision of mantissa from p to P, so we also need to increment the exponent by P-p.
        Overall, this means adding (P-p)-(P-ell) = ell-p to the exponent.
    '''
    ell = msnzb(m, P+1)
    m <<= (P - ell)
    e = e + ell - p
    return (e, m)

''' Rounds the input floating-point number and checks to ensure that rounding does not make the mantissa unnormalized.
    Rounding is necessary to prevent the bitlength of the mantissa from growing with each successive operation.
    The input is a normalized floating-point number (e, m) with precision `P`, where `e` is a `k`-bit exponent and `m` is a `P`+1-bit mantissa.
    The output is a normalized floating-point number (e_out, m_out) representing the same value with a lower precision `p`.
'''
def round_nearest_and_check(k, p, P, e, m):
    ''' if mantissa >= 2^(P+1) - 2^(P-p-1), then rounding by P-p bits outputs 2^{p+1}, which is unnormalized
        Thus, in this case, we increment the exponent by 1 and set the mantissa to 2^p
        otherwise, we round m by P-p bits to the nearest value, i.e., \lfloor m / 2^{P-p} \rceil = (m + 2^{P-p-1}) >> P-p
    '''
    if m >= ((2 ** (P+1)) - (2 ** (P-p-1))):
        return (e + 1, 2 ** p)
    else:
        shift_amt = P-p
        rounded_m = (m + (2 ** (shift_amt-1))) >> shift_amt
        return (e, rounded_m)

''' Adds two floating-point numbers.
    The inputs are normalized floating-point numbers with `k`-bit exponents `e` and `p`+1-bit mantissas `m` with precision `p`.
    The output is a normalized floating-point number with exponent `e_out` and a `p`+1-bit mantissa with precision `p`.
'''
def float_add(k, p, e_1, m_1, e_2, m_2):
    ''' check that the inputs are well-formed '''
    check_well_formedness(k, p, e_1, m_1)
    check_well_formedness(k, p, e_2, m_2)

    ''' Arrange numbers in the order of their magnitude.
        Although not the same as magnitude, note that comparing e_1 || m_1 against e_2 || m_2 suffices to compare magnitudes.
    '''
    mgn_1 = (e_1 << (p+1)) + m_1
    mgn_2 = (e_2 << (p+1)) + m_2
    ''' comparison over k+p+1 bits '''
    if mgn_1 > mgn_2:
        (alpha_e, alpha_m) = (e_1, m_1)
        (beta_e, beta_m) = (e_2, m_2)
    else:
        (alpha_e, alpha_m) = (e_2, m_2)
        (beta_e, beta_m) = (e_1, m_1)

    ''' If the difference in exponents is > p + 1, the result is alpha because the smaller value will be ignored entirely during the final rounding step.
        Else, the result is the sum of the two numbers.
    '''
    diff = alpha_e - beta_e
    if diff > p + 1 or alpha_e == 0:
        ''' Simply return the larger number alpha '''
        return (alpha_e, alpha_m)
    else:
        ''' Left-shift `alpha_m` by `diff` to align the mantissas, i.e., make the corresponding exponents equal.
            Note that (e, m) and (e - diff, 2^diff * m) represent the same value.
        '''
        alpha_m <<= diff
        ''' Add the aligned mantissas to get an unnormalized output mantissa.
            The sum of the aligned mantissas `m` is guaranteed to fit in 2*p+2 bits.
        ''' 
        m = alpha_m + beta_m
        ''' The aligned mantissa have the same exponent, i.e., `beta_e` '''
        e = beta_e
        ''' Now, we have an unnormalized mantissa in 2*p+2 bits with precision `p`, same as that of the input mantissas.
            We need to normalize this mantissa such that it lies in the range [2^{2p+1}, 2^{2p+2}) and has precision 2p+1.
            To ensure that our exponent-mantissa pair is still representing the same value, we also adjust the exponent accordingly.
        '''
        (normalized_e, normalized_m) = normalize(k, p, 2*p+1, e, m)
        ''' Now, we have a normalized mantissa in 2*p+2 bits with precision 2p+1.
            To get the same format as the inputs, we round this mantissa by p+1 bits to get a p+1-bit mantissa with precision p.
        '''
        (e_out, m_out) = round_nearest_and_check(k, p, 2*p+1, normalized_e, normalized_m)

        return (e_out, m_out)
