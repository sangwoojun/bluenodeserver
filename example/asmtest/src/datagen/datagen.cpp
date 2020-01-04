#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include <time.h>

#include <string>
#include <algorithm>

int 
main( int argc, char** argv) {
	if ( argc < 3 ) {
		exit(1);
	}

	srand(time(NULL));

	int size = atoi(argv[2]);
	if ( size > 1024 ) {
		printf( "data size too large\n" );
		exit(1);
	}

	printf( "data size: %d\n", size );

	FILE* fdat = fopen("./obj/dataset.bin", "wb");
	FILE* fmap = fopen("./obj/mmap.txt", "w");
	fprintf( fmap, "+0 obj/binary.bin\n" );
	fprintf( fmap, "+8192 obj/dataset.bin\n" );
	fflush(fmap);

	std::string mode(argv[1]);

	if ( mode.find("max") != std::string::npos ) {
		//printf( "max1" );
		int32_t databuf[1024];
		int32_t max = INT32_MIN;
		int idx = 0;
		
		printf( "Generated data " );
		for ( int i = 0; i < size; i++ ) {
			databuf[i] = (rand()%2048) - 1024;
			printf( "%d ", databuf[i] );
			if ( databuf[i] >= max ) {
				idx = i;
				max = databuf[i];
			}
		}
		printf( "\n");
		printf( "Max value is %d at %d\n", max, idx );
		fwrite(databuf, sizeof(int32_t), size, fdat);
		fprintf(fmap, "?12288 %d\n", idx);
		fprintf(fmap, "?12292 %d\n", databuf[0]);
		fprintf(fmap, "?12296 %d\n", databuf[1]);
		fclose(fmap);
		fclose(fdat);
	} else if ( mode.find("gcd") != std::string::npos ) {
		uint32_t seed = (rand()%12)+5;
		uint32_t databuf[2];
		uint32_t a = rand()%(32-4) + 4;
		a *= seed;
		uint32_t b = rand()%(32-3) + 3;
		b *= seed;
		databuf[0] = a;
		databuf[1] = b;
		printf( "Generated data %d and %d\n", a,b );
		fwrite(databuf, sizeof(uint32_t), 2, fdat);

		while ( b > 0 ) {
			if ( b >= a ) b -= a;
			else {
				uint32_t t = a;
				a = b;
				b = t;
			}
			printf( "%d %d\n", a,b  );
		}

		printf( "GCD is %d\n", a );


		fprintf(fmap, "?12288 %d\n", a);
		fprintf(fmap, "?12292 %d\n", databuf[0]);
		fprintf(fmap, "?12296 %d\n", databuf[1]);
		fclose(fmap);
		fclose(fdat);


	} else if ( mode.find("sort") != std::string::npos ) {
		int32_t databuf[1024];
		printf( "Generated data " );
		for ( int i = 0; i < size; i++ ) {
			databuf[i] = (rand()%2048) - 1024;
			printf( "%d ", databuf[i] );
		}
		printf( "\n");
		fwrite(databuf, sizeof(int32_t), size, fdat);

		std::sort(databuf, databuf + size);
		printf( "Sorted: " );
		for ( int i = 0; i < size; i++ ) {
			printf( "%d ", databuf[i] );
		}
		printf("\n");
		printf( "Median should be %d\n", databuf[size/2] );


		fprintf(fmap, "?12288 %d\n", databuf[size/2]);
		fprintf(fmap, "?12292 %d\n", databuf[0]);
		fprintf(fmap, "?12296 %d\n", databuf[1]);
		fclose(fmap);
		fclose(fdat);
	} else {
		printf( "Not valid mode %s...\n", argv[1] );
		exit(1);
	}

	exit(0);
}
