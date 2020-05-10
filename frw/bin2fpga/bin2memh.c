/*
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *  
 *	Copyright @ Lyu Yang
 */

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv)
{
	int i, j, FileLen = 0, address = 0, maxaddr;
	FILE *FileIn;

	if (argc != 3) {
		fprintf(stderr, "Arguments Error!\n");
		fprintf(stderr, "\nUsage: bin2fpga.exe Depth InputFile\n");
		return 0;
	}
	else {

		FileIn = fopen(*(argv + 2), "rb");
		if (FileIn == NULL){
			fprintf(stderr, "File does not exist!\n");
			return 0;
		}

		fseek(FileIn, 0L, SEEK_END);
		FileLen = ftell(FileIn);

		maxaddr = atoi(*(argv + 1));
		
		unsigned char * buf = (unsigned char*)malloc(sizeof(char)* FileLen);
		if(buf == NULL) {
			fprintf(stderr, "Memory Allocate Error!\n");
			return 0;
		}

		address = 0x0;
		fseek(FileIn, 0L, SEEK_SET);
		fread(buf, FileLen, 1, FileIn);
			
		for (i = 0; i < FileLen; i += 4) {
			fprintf(stdout, "@%08x\n", address);

			fprintf(stdout, "%02x", buf[i + 3]);
			fprintf(stdout, "%02x", buf[i + 2]);
			fprintf(stdout, "%02x", buf[i + 1]);
			fprintf(stdout, "%02x", buf[i + 0]);
			fprintf(stdout, "\n");
			address++;
		}
		
		free(buf);
		fclose(FileIn);
	}
	
	return 0;
}
