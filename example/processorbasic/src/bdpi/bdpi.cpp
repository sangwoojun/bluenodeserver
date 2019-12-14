#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <map>

#define MEM_SIZE 0x10000
bool g_init = false;
void* g_mem;

std::map<uint32_t, int> g_answermap;



void init() {
	if ( g_init ) return;
	g_init = true;
	g_mem = malloc(MEM_SIZE); // 64KB
	memset(g_mem, 0, MEM_SIZE);

	FILE* fmmap = fopen("./mmap.txt", "r");
	char rbuf[128];
	while(!feof(fmmap)) {
		char* cin = fgets(rbuf, 128, fmmap);
		if (!cin) continue;
		if ( rbuf[0] == '#' ) continue;
		if ( rbuf[0] == '+' ) { // load file
			char* tok = strtok(rbuf, " \t");
			tok++;
			uint32_t addr = atoi(tok);
			tok = strtok(NULL, " \t");
			FILE* fdin = fopen(tok, "rb");
			if ( !fdin ) continue;
			fseek(fdin, 0, SEEK_END);
			size_t sz = ftell(fdin);
			if ( sz > MEM_SIZE - addr ) sz = MEM_SIZE-addr;
			fseek(fdin, 0, SEEK_SET);
			uint8_t* loadp = ((uint8_t*)g_mem)+addr;
			int readb = fread(loadp, 1, sz, fdin);
		}
		if ( rbuf[0] == '?' ) { // answer check
			char* tok = strtok(rbuf, " \t");
			tok++;
			uint32_t addr = atoi(tok);
			tok = strtok(NULL, " \t");
			int ans = atoi(tok);
			g_answermap[addr] = ans;
			printf( "Answer for addr %d is %d\n", addr, ans );
		}
	}

	FILE* objbin = fopen("./benchmarks/test.bin", "rb");
	size_t r = fread(g_mem, 4, 0x10000/4, objbin);
	printf( "binary read, %ld bytes\n", r );
}

extern "C" uint32_t memRead(uint32_t addr, uint32_t bytes) {
	init();

	uint8_t* p = ((uint8_t*)g_mem)+addr;
	uint32_t r = *(uint32_t*)p;
	if ( bytes == 1 ) r = (uint32_t)(*p);
	else if ( bytes == 2 ) r = (uint32_t)(*(uint16_t*)p);


	//printf( "Mem read req (%d) %x, %x\n", bytes, addr, r );
	return r;
}


extern "C" void memWrite(uint32_t addr, uint32_t bytes, uint32_t data) {
	init();
	if ( g_answermap.find(addr) != g_answermap.end() ) {
		int correct = g_answermap[addr];
		int given = *(int*)&data;
		if ( correct == given ) {
			printf( "CORRECT! Writing %d to address %x\n", given, addr );
		} else {
			printf( "INCORRECT! Writing %d to address %x, should be %d\n", given, addr, correct );
		}
		return;
	}
	//printf( "Mem write req (%d) %x, %x\n", bytes, addr, data );
	uint8_t* p = ((uint8_t*)g_mem)+addr;
	if ( bytes == 1 ) {
		*p = (uint8_t)(data&0xff);
	} else if ( bytes == 2 ) {
		*((uint16_t*)p) = (uint16_t)(data&0xffff);
	} else {
		*((uint32_t*)p) = data;
	}

	//if ( addr == 0x800 ) printf( "!! Map IO %x -- %x\n", addr, data );
}
