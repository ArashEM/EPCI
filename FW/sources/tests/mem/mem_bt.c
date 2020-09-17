/**
*  EPCI memory black box test programm
*/
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>

const int   mem_size = 32768;
const char *mem_path = "/dev/epci-mem"; 

int main(int argc, char *argv[])
{
    FILE   *pfile;
    char   *wbuffer,*rbuffer;
    int     index;
    size_t  result;
    int     ret;

    /* open epci-mem to read/write */
    pfile = fopen(mem_path, "r+");
    if(pfile == NULL) {
        perror("fopen");
        return errno;
    } 

    /* allocate memory for buffer */
    wbuffer = (char *)malloc(mem_size);
    if(wbuffer == NULL) {
        perror("w malloc");
        return errno;
    }
    rbuffer = (char *)malloc(mem_size);
    if(rbuffer == NULL) {
        perror("r malloc");
        return errno;
    }

	srand(time(NULL));   // Initialization, should only be called once.

    /* fill buffer with sequence of random numbers */
    for(index=0; index < mem_size; index++)
        wbuffer[index] = (char)rand();

    /* fill /dev/epci-mem with buffer */
    result = fwrite(wbuffer, sizeof(char), mem_size, pfile);
    if(result < 0) {
        perror("fwrite");
        return errno;
    }

    /* Seek to the beginning of the file */
    fseek(pfile, 0, SEEK_SET);

    /* read all data from epci */
    result = fread(rbuffer, sizeof(char), mem_size, pfile);
    if(result < 0) {
        perror("fread");
        return errno;
    }

    /* check read/write value */
    for(index=0;index < mem_size; index++)
        if(wbuffer[index] != rbuffer[index]) {
            printf("Error in address:0x%08x\r\n",index);
            printf("Read  value:0x%02x\r\n",rbuffer[index]);
            printf("Write value:0x%02x\r\n",wbuffer[index]);
            ret = -EINVAL;
            break;
        }
		else ret = 0;

cleanup:
    fclose(pfile);
    free(wbuffer);
    free(rbuffer);
    return ret;
}
