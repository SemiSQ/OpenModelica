
function pivot2
  input Real b[6,9];
  input Integer p;
  input Integer q;

  output Real a[6,9];

protected
  Real row[9];
  Real col[6];
  
algorithm
  
  row := b[p,:];
  col := b[:,q] * (1 / b[p,q]);

  for j in 1:size(b,1) loop

    a[j,:] := b[j,:] - row * col[j];
    a[j,q] := 0.0;

  end for;

  a[p,q] := 1.0;

end pivot2;

function misc_simplex2

  input Real matr[6,9];

  output Real x[8];
  output Real z;

  
protected
  Real a[6,9];
  Integer M;
  Integer N;
output  Integer q;
output  Integer p;

algorithm

  N := size(a,1)-1;
  M := size(a,2)-1;

  a := matr;

  p:=0;q:=0;
  while not (q==(M+1) or p==(N+1)) loop

    q := 1;
    while not (q == (M+1) or (a[1,q] < 0)) loop
      q:=q+1;
    end while;

    p := 1;
    while not (p == (N+1) or a[p+1,q+1] > 0) loop
      p:=p+1;
    end while;
    
    
    for i in p+1:N loop
      if a[i,q] > 0 then
	if (a[i,M+1]/a[i,q]) < (a[p,M+1]/a[p,q]) then
	  p := i;
	end if;
      end if;
    end for;

    
    if (q < M+1) and (p < N+1) then
      a := pivot2(a,p,q);
    end if;

  end while;

  for i in 1:M loop
    x[i] := -1;
    for j in 2:N+1 loop
      if (x[i] < 0) and ((a[j,i] >= 1.0) and (a[j,i] <= 1.0)) then
	x[i] := a[j,M+1];
      elseif ((a[j,i] < 0) or (a[j,i] > 0)) then
	x[i] := 0;	
      end if;
    end for;
  end for;

  z := a[1,M+1];

end misc_simplex;

model mo
end mo;
