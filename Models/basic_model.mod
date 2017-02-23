## Very basic non linear example
var x1;
var x2;

maximize final_result: x1 + x2;
subject to constraint_1: x2 <= 5;
subject to constraint_2: x1^2 + x2 <= 10;
