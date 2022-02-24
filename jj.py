
m = [[1,0,0,0,0],[0,0,0,0,0],[0.2,0.4,0.4,0,0],[0.1,0.1,0.1,0.1,0.6],[0,0,0,0,0]]

def num_of_transients(m):
    if len(m) == 0:
        raise Exception("Can't get transient states of empty matrix")

    for r in range(len(m)):
        for c in range(len(m[r])):
            if m[r][c] != 0:
                # this is not an all-zero row, try next one
                break
        else:
            # has just finished looping over an empty row (i.e. w/o `break`)
            return r
    # reached end of table and didn't encounter all-zero row - no absorbing states
    raise Exception("Not a valid AMC matrix: no absorbing (terminal) states")


# decompose input matrix `m` on Q (t-by-t) and R (t-by-r) components
# `t` is the number of transient states
def decompose(m):
    t = num_of_transients(m)
    if t == 0:
        raise Exception("No transient states. At least initial state is needed.")

    Q = []
    for r in range(t):
        qRow = []
        for c in range(t):
            qRow.append(m[r][c])
        Q.append(qRow)
    if Q == []:
        raise Exception("Not a valid AMC matrix: no transient states")

    R = []
    for r in range(t):
        rRow = []
        for c in range(t, len(m[r])):
            rRow.append(m[r][c])
        R.append(rRow)
    if R == []:
        raise Exception("Not a valid AMC matrix: missing absorbing states")
    return Q, R

Q, R =decompose(m)
print(Q)
print(R)