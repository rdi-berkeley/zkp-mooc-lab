import random

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

''' Normalizes the input floating-point number.'''
def normalize(k, p, P, e, m):
    assert(P > p and m != 0)
    ell = msnzb(m, P+1)
    m <<= (P - ell)
    e = e + ell - p
    return (e, m)

''' Rounds the input floating-point number and checks to ensure that rounding does not make the mantissa unnormalized.'''
def round_nearest_and_check(k, p, P, e, m):
    if m >= ((2 ** (P+1)) - (2 ** (P-p-1))):
        return (e + 1, 2 ** p)
    else:
        shift_amt = P-p
        rounded_m = (m + (2 ** (shift_amt-1))) >> shift_amt
        return (e, rounded_m)

''' Adds two floating-point numbers.
    The inputs are normalized floating-point numbers with `k`-bit exponents `e` and `p`+1-bit mantissas `m`.
'''
def float_add(k, p, e_1, m_1, e_2, m_2):
    check_well_formedness(k, p, e_1, m_1)
    check_well_formedness(k, p, e_2, m_2)

    ''' Arrange numbers in the order of their magnitude.
        Although not the same as magnitude, comparing e_1 || m_1 against e_2 || m_2 suffices to compare magnitudes.
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

    diff = alpha_e - beta_e
    if diff > p + 1 or alpha_e == 0:
        return (alpha_e, alpha_m)
    else:
        alpha_m <<= diff
        ''' m fits in 2*p+2 bits '''
        m = alpha_m + beta_m
        e = beta_e
        (normalized_e, normalized_m) = normalize(k, p, 2*p+1, e, m)
        (e_out, m_out) = round_nearest_and_check(k, p, 2*p+1, normalized_e, normalized_m)

        return (e_out, m_out)

##########################################################################

def get_bias(k):
    return (2 ** (k - 1)) - 1

def float_to_string(k, p, exponent, mantissa):
    if exponent == 0:
        return "0.0"
    else:
        return str(mantissa/(2 ** p) * (2 ** (exponent - get_bias(k))))

def sample_float(k, p):
    # sampling from a small range to make the test cases hit each case
    exponent = random.randint(2 ** (k-1), 2 ** (k-1) + 2*p)
    mantissa = random.randint(0, 2 ** p - 1)
    if exponent != 0:
        mantissa += 2 ** p
    else:
        mantissa = 0
    return (exponent, mantissa)

def test_float_add():
    for i in range(100):
        k = 8
        p = 23
        (exponent_1, mantissa_1) = sample_float(k, p)
        (exponent_2, mantissa_2) = sample_float(k, p)
        exponent_2 = exponent_1 - (p+1)
        (exponent, mantissa) = float_add(k, p, exponent_1, mantissa_1, exponent_2, mantissa_2)
        print("------------------------test", i, "------------------------")
        print("input_1", float_to_string(k, p, exponent_1, mantissa_1), "exponent:", exponent_1, "mantissa:", mantissa_1)
        print("input_2", float_to_string(k, p, exponent_2, mantissa_2), "exponent:", exponent_2, "mantissa:", mantissa_2)
        print("output", float_to_string(k, p, exponent, mantissa), "exponent:", exponent, "mantissa:", mantissa)

if __name__ == "__main__":
    test_float_add()
