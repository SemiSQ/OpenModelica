// name:     BlockMatrix2
// keywords: array
// status:   incorrect

class BlockMatrix2
  Real[3, 3]	P = [ 1, 2, 3; 
  				4, 5, 6; 
  				7, 8, 9];				
  Real[6, 6]	Q;								
equation
  Q[1:3, 1:3] = P;	// Upper left block
  Q[1:3, 4:6] = [Q[1:3, 1:2], -Q[1:3, 3:3]];	// Upper right block
  Q[4:6, 1:3] = [Q[1:2, 1:3], -Q[3:3, 1:3]];	// Lower left block
  Q[4:6, 4:6] = P;	// Lower right block
end BlockMatrix2;

