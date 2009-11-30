package Main

protected import Parse;
protected import Pam;

public function main "Parse and translate a PAM program into MCode,
  then emit it as textual assembly code.
"
  output Integer out;
  Pam.Stmt program;
algorithm
  print("[Parse. Enter a program, then press CTRL+z (Windows) or CTRL+d (Linux).]\n"); 
  program := Parse.parse();
  _ := Pam.evalStmt({}, program);
  out := 0;
end main;
end Main;

