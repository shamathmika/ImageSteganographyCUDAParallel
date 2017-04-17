
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <math.h>
#include <conio.h>
#include <time.h>

#define MAX_IMAGE_HEIGHT 512
#define MAX_IMAGE_WIDTH 512

__global__ void hide(int *pixels_per_process, int *text_size, char *text, unsigned char *intermediate_b, char *final_b, int *wid)
{
	int id = threadIdx.x;
	int size = blockDim.x;
	int i = id, j;
	int bits_written = 0;
	int index = id * (*text_size) / size;
	int start_index = index;
	char c = text[start_index];
	int mask = 1;
	int flag = 0;
	

	
	///*
	for (i = id * *pixels_per_process; i < (id+1) * *pixels_per_process; i++)
	{ 
	//*/
		for (j = 0; j < *wid; j++)
		{
			flag = 0;
			if (bits_written == 8)
			{
				if (index < (start_index + (*text_size) / size - 1))
				{
					c = text[++index];
					bits_written = 0;
					mask = 1;
					j = j - 1;
				}
				else
				{
					flag = 1;
					break;
				}
			}
			else
			{
				char ch = c & mask;
				int m = log((double)mask) / log((double)2);
				ch = ch >> m;
				unsigned char temp = intermediate_b[(i )* (*wid) + j] & 0xFE;
				intermediate_b[(i)* (*wid) + j] = intermediate_b[(i )* (*wid) + j] & 0xFE;
				intermediate_b[(i)* (*wid) + j] = intermediate_b[(i )* (*wid) + j] | ch;


				mask = mask << 1;
				bits_written++;
			}
		}
		///*
		if (flag == 1)
		{
			break;
		}
	}  //*/
	for (i = id*(*pixels_per_process); i < (id + 1)*(*pixels_per_process); i++)
	{
		for (j = 0; j < MAX_IMAGE_WIDTH; j++)
		{
			final_b[(i)* (*wid) + j] = intermediate_b[(i)* (*wid) + j];
		}
	}

}


/*
__global__ void  unhide(unsigned char *blue, int *wid, int *pixels_per_process, int* text_size, char *text, char *bits)
{
	int id = threadIdx.x;
	int size = blockDim.x;
	int i, j;
	int index = 8 * id * *text_size / size;
	int start_index = index;
	int ind = id * *text_size / size;
	int st = id * *pixels_per_process * *wid;
	for (i = start_index, j=0;i < start_index + (8 * *text_size / size); i++)
	{
		bits[i] = blue[st + j] & 0x01;
		j++;
	}


	int c = 0;

	for (j = 0; j < 6; j++)
	{
		c = 0;
		for (i = start_index; i < start_index + 8; i++)
		{
			c = c << 1;
			c = c | bits[j * 8 + 7 - i];
		}
		//printf("\nID:%d  c: %c", id, c);

		text[ind++] = c;
	}

}
  */



int main()
{
	float start, end;
	start = clock();

	int size = 5, text_size1, i, j, height, width, padding, pixels_per_process1;
	static unsigned char header[54], r[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH], g[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH], b[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH], final_r[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH], final_g[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH], final_b1[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH], intermediate_r[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH], intermediate_g[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH], intermediate_b1[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH], text1[(MAX_IMAGE_HEIGHT * MAX_IMAGE_WIDTH) / 8];

	
	

	char *image_input = "airplane.bmp";
	char *text_input = "abc.txt";
	char *image_output = "a1.bmp";
	char *text_output = "abc_out.txt";


	printf("Input image: %s\n", image_input);

	FILE *fd, *store_pixels;

	fd = fopen(image_input, "rb");

	if (fd == NULL)
	{
		printf("Error: fopen failed for %s\n", image_input);
		return 0;
	}

	store_pixels = fopen("store_input_pixels.txt", "w+");

	if (store_pixels == NULL)
	{
		printf("Error: fopen failed for store_input_pixels\n");
		return 0;
	}

	/* Read header for height, width information */

	fread(header, sizeof(unsigned char), 54, fd);

	width = *(int*)&header[18];
	height = *(int*)&header[22];
	padding = 0;

	pixels_per_process1 = height / size;


	while ((width * 3 + padding) % 4 != 0)
	{
		padding++;
	}

	printf("Dimensions of %s: %d x %d pixels\n", image_input, height, width);
	printf("Image padding: %d\n", padding);

	static unsigned char image[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH][3];

	for (i = 0, j = 0; i<height; j++)
	{
		fread(image[i][j], sizeof(unsigned char), 3, fd);
		fprintf(store_pixels, "image[%d][%d] = %d %d %d\n", i, j, image[i][j][0], image[i][j][1], image[i][j][2]);
		r[i][j] = image[i][j][0];
		g[i][j] = image[i][j][1];
		b[i][j] = image[i][j][2];
		if (j == (width - 1))
		{
			j = -1;
			i++;
		}
	}
	fclose(fd);

	/* Reading the text file */

	printf("Text file to be hidden: %s\n", text_input);

	FILE *f = fopen(text_input, "r");

	if (f == NULL)
	{
		printf("Error: fopen failed for %s\n", text_input);
		return 0;
	}

	fseek(f, 0, SEEK_END);
	text_size1 = ftell(f);
	fprintf(stdout, "Size of %s: %d characters\n", text_input, text_size1);
	fseek(f, 0, SEEK_SET);
	fread(text1, sizeof(unsigned char), text_size1, fd);
	text1[text_size1] = '\0';
	fprintf(stdout, "Text in %s: %s\n\n", text_input, text1);


	for (i = 0; i < MAX_IMAGE_HEIGHT; i++)
	{
		for (j = 0; j < MAX_IMAGE_WIDTH; j++)
		{
			intermediate_r[i][j] = r[i][j];
			intermediate_g[i][j] = g[i][j];
			intermediate_b1[i][j] = b[i][j];
		}
	}


	int *pixels_per_process;
	int *text_size;
	char *text;
	unsigned char *intermediate_b;
	char *final_b;
	int *wid;

	cudaMalloc((void**)&pixels_per_process, sizeof(int));
	cudaMalloc((void**)&text_size, sizeof(int));
	cudaMalloc((void**)&text, text_size1 * sizeof(char));
	cudaMalloc((void**)&intermediate_b, MAX_IMAGE_HEIGHT * MAX_IMAGE_WIDTH * sizeof(unsigned char));
	cudaMalloc((void**)&final_b, MAX_IMAGE_HEIGHT * MAX_IMAGE_WIDTH * sizeof(char));
	cudaMalloc((void**)&wid, sizeof(int));


	cudaMemcpy(pixels_per_process, &pixels_per_process1, sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(text_size, &text_size1, sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(text, &text1, text_size1 * sizeof(char), cudaMemcpyHostToDevice);
	cudaMemcpy(intermediate_b, intermediate_b1, MAX_IMAGE_HEIGHT * MAX_IMAGE_WIDTH * sizeof(unsigned char), cudaMemcpyHostToDevice);
	cudaMemcpy(wid, &width, sizeof(int), cudaMemcpyHostToDevice);

	hide << <1, 5 >> >(pixels_per_process, text_size, text, intermediate_b, final_b, wid);

	cudaMemcpy(final_b1, final_b, MAX_IMAGE_HEIGHT * MAX_IMAGE_WIDTH * sizeof(char), cudaMemcpyDeviceToHost);
	cudaMemcpy(intermediate_b1, intermediate_b, MAX_IMAGE_HEIGHT * MAX_IMAGE_WIDTH * sizeof(char), cudaMemcpyDeviceToHost);

	unsigned char final_image[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH][3];

	for (i = 0; i < height; i++)
	{
		for (j = 0; j < width; j++)
		{
			final_image[i][j][0] = intermediate_r[i][j];
			final_image[i][j][1] = intermediate_g[i][j];
			final_image[i][j][2] = intermediate_b1[i][j];
		}
	}

	printf("\nOutput image %s\n", image_output);
	printf("Dimensions of %s: %d x %d pixels\n", image_output, height, width);

	/* Write final_image into image_output */


	FILE *fd1;


	fd1 = fopen(image_output, "wb");
	if (fd1 == NULL)
	{
		printf("Error: fopen failed for %s\n", image_output);
		return 0;
	}

	fwrite(header, sizeof(unsigned char), 54, fd1);
	for (i = 0; i<height; i++)
	{
		for (j = 0; j<width; j++)
		{
			fwrite(final_image[i][j], sizeof(unsigned char), 3, fd1);
		}
	}

	fclose(fd1);

	FILE *fk;

	fk = fopen("store_output_pixels.txt", "w+");

	if (fk == NULL)
	{
		printf("Error: fopen failed for store_output_pixels.txt\n");
		return 0;
	}


	for (i = 0, j = 0; i<height; j++)
	{
		fprintf(fk, "image[%d][%d] = %d %d %d\n", i, j, final_image[i][j][0], final_image[i][j][1], final_image[i][j][2]);
		if (j == (width - 1))
		{
			j = -1;
			i++;
		}
	}
	fclose(fk);
	printf("\nDone\n");



	/* Retrieving data back */

  /*
	unsigned char blue[MAX_IMAGE_HEIGHT ][ MAX_IMAGE_WIDTH];

	for (i = 0, j = 0; i < height; j++)
	{
		blue[i][j] = final_image[i][j][2];
		if (j == (width - 1))
		{
			j = -1;
			i++;
		}
	}

	unsigned char *blue1;
	char *read_text1, read_text[MAX_IMAGE_HEIGHT * MAX_IMAGE_WIDTH];
	char *bits1;

	cudaMalloc((void **)&blue1, MAX_IMAGE_HEIGHT * MAX_IMAGE_WIDTH * sizeof(unsigned char));
	cudaMalloc((void **)&read_text1, text_size1 * sizeof(char));
	cudaMalloc((void **)&bits1, 8 * text_size1 * sizeof(char));
	cudaMemcpy(blue1, blue, MAX_IMAGE_HEIGHT * MAX_IMAGE_WIDTH * sizeof(unsigned char), cudaMemcpyHostToDevice);

	unhide << <1, 5 >> > (blue1, wid, pixels_per_process, text_size, read_text, bits1);

	cudaMemcpy(read_text, read_text1, text_size1 * sizeof(char), cudaMemcpyDeviceToHost);

	printf("\n\nRetrieved: %s\n", read_text);
	*/

	cudaFree(pixels_per_process);
	cudaFree(text_size);							 
	cudaFree(text);
	cudaFree(intermediate_b);
	cudaFree(final_b);
	cudaFree(wid);
	//cudaFree(blue1);

	end = clock();

	printf("\nTotal time taken: %f\n", (end - start) / CLOCKS_PER_SEC);

	return 0;
}