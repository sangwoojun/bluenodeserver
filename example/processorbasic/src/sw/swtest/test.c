int inita = 12;

int volatile * const p_reg = (int *) 0x800;
int foo(int a, char b) {
	*p_reg = a;
	if ( a == 0 ) return b;
	return foo(a-1, b+1);
}

int _start() {
	int b = foo(inita,2);
	*p_reg = 0xdeadbeef;
	return b;
}

