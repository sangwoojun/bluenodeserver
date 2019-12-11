#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

bool g_init = false;
void* g_mem;

void init() {
	if ( g_init ) return;
	g_init = true;

	g_mem = malloc(0x10000); // 64KB
	FILE* objbin = fopen("../benchmarks/test.bin", "rb");
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
	//printf( "Mem write req (%d) %x, %x\n", bytes, addr, data );
	uint8_t* p = ((uint8_t*)g_mem)+addr;
	if ( bytes == 1 ) {
		*p = (uint8_t)(data&0xff);
	} else if ( bytes == 2 ) {
		*((uint16_t*)p) = (uint16_t)(data&0xffff);
	} else {
		*((uint32_t*)p) = data;
	}

	if ( addr == 0x800 ) printf( "!! Map IO %x -- %x\n", addr, data );
}
