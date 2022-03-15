P =[
0.4  0.1  0.5;
0  0.3  0.7;
0.4  0  0.6]

# Check that steady state probabilities exist. E.g. see that all entries of P are >0 for e.g. P2
P^2

A =[
-0.6  0  0.4;
0.1  -0.7  0;
0.5  0.7  -0.4;
1    1  1 ]

b = [0; 0; 0; 1]

pi = A\b
#answer:  0.37837837837837834
# 0.054054054054054126
# 0.5675675675675674

#You can always check your answer by computing A*pi, and check that it equals b:
A*pi

#You can see below that when you solve the system of equatins with
#one less equation, you still get the same answer.
A =[
-0.6  0  0.4;
0.1  -0.7  0;
1    1  1 ]

b = [ 0; 0; 1]

pi = A\b


#You can always check your answer by computing A*pi, and check that it equals b:
A*pi
