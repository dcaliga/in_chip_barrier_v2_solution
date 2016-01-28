#include <libmap.h>

// We are spliting up the such that npoint * numvec is the number of total samples in the line

void subr (int64_t In[], int64_t Out[], int npoint, int numvec, int Num_Lines, int64_t *tm, int mapnum) {

    OBM_BANK_A (A, int64_t, MAX_OBM_SIZE)
    OBM_BANK_B (B, int64_t, MAX_OBM_SIZE)
    OBM_BANK_C (C, int64_t, MAX_OBM_SIZE)
    OBM_BANK_D (D, int64_t, MAX_OBM_SIZE)

    Stream_64 S0,S3,S4,S5,S6,S7,S8;

    int64_t v0;
    int j, nval_in, nval_out, n_line, n_sample;
    int64_t t0,t1;

    In_Chip_Barrier B0, B1;
    
// need to bring over dummy at beginning and end
// this is done to deal with feeding the ping-ponging process

    nval_in  = (numvec * npoint) * (Num_Lines+2);
    nval_out = (numvec * npoint) * Num_Lines;


   In_Chip_Barrier_Set (&B0, 2);
   In_Chip_Barrier_Set (&B1, 2);

    read_timer (&t0);

    #pragma src parallel sections
    {
        #pragma src section
        {
        streamed_dma_cpu_64 (&S0, PORT_TO_STREAM, In, nval_in*8);

        stream_64_term (&S0);
        }

        #pragma src section
        {
            
               printf("                                                      + : mxn_term 1 start.\n");
               
          stream_split_64_mxn_term (&S0, &S3, &S4, numvec*npoint, numvec*npoint);
               
               printf("                                                      - : mxn_term 1 complete.\n");
               
         }
            
/////////////////////////////////////////////////////////////////////
//  ping/ping:
//    [write OBM D, read OBM C]
//    [write OBM C, read OBM D]
         #pragma src section
         {
               int      j, k;
               int64_t  i64, o64;
               int32_t r32, i32;
               int odd_number_of_lines;
               int iput;

               int N = Num_Lines - (Num_Lines/2);

               odd_number_of_lines = Num_Lines & 1;

               printf("                                                      + : Even Pingpong start.\n");

               for (k=0; k<N+1; k++) {

                  // even line
                  for (j = 0; j < npoint*numvec; j++) {
                     get_stream_64 (&S3, &i64);
                     D[(j%numvec)*npoint+j/numvec]=i64;

                     o64=C[j];

                     iput = (k>0) ? 1 : 0;
                     put_stream_64 (&S5, o64,iput);
                  }  // for j loop

                  if ((k < N-1) | (odd_number_of_lines == 0)) {
                      In_Chip_Barrier_Wait (&B0);
                      In_Chip_Barrier_Wait (&B1);
                      }

               }  // for k loop

               stream_64_term (&S5);

               printf("                                                      - : Even Pingpong complete.\n");

          }  // end parallel section

/////////////////////////////////////////////////////////////////////
//  ping/ping:
//    [write OBM D, read OBM C]
//    [write OBM C, read OBM D]
          #pragma src section
          {
               int      j, k;
               int64_t  i64, o64;
               int32_t r32, i32;
               int iput;

               int N = Num_Lines/2;

               printf("                                                      + : Odd Pingpong start.\n");

               for (k=0; k<N+1; k++) {

                  In_Chip_Barrier_Wait (&B0);

                  // odd line
                  for (j = 0; j < npoint*numvec; j++) {
                     get_stream_64 (&S4, &i64);
                     C[(j%numvec)*npoint+j/numvec]=i64;

                     o64=D[j];

                     iput = (k>0) ? 1 : 0;
                     put_stream_64 (&S6, o64,iput);
                  }  // for j loop

                 In_Chip_Barrier_Wait (&B1);
               }  // for k loop

               stream_64_term (&S6);

               printf("                                                      - : Odd Pingpong complete.\n");

          }  // end parallel section

/////////////////////////////////////////////////////////////////////
          #pragma src section
          {

               printf("                                                      + : mxn 2 start.\n");

               stream_merge_64_mxn_term (&S5, &S6, &S7, numvec*npoint, numvec*npoint);

               printf("                                                      - : mxn 2 complete.\n");

           }  // end parallel section

           #pragma src section
           {
                int i,j,k;
                int64_t i64;

                i = 0;
               for (k=0; k<Num_Lines; k++) {
                  for (j = 0; j < npoint*numvec; j++) {
                     get_stream_64 (&S7, &i64);

                     //B[i] = i64;
                     //i++;
                     put_stream_64 (&S8, i64, 1);

                   }
               }
                  
           }
           #pragma src section
           {
              streamed_dma_cpu_64 (&S8, STREAM_TO_PORT, Out, nval_out*8);
           }
        } // end of par region


    read_timer (&t1);
    *tm = t1 - t0;

    //nval = (numvec * npoint) * (Num_Lines);
    //buffered_dma_gcm (OBM2CM, PATH_0, B, MAP_OBM_stripe(1,"B"), Out, 1, nval*8);
}
