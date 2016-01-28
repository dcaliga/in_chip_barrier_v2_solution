#include <libmap.h>

void subr (gcm_addr_t In, gcm_addr_t Out, int npoint, int numvec, int Num_Lines, int64_t *tm, int mapnum) ;


int main (int argc, char *argv[]) {

    FILE *res_map, *res_cpu;
    int64_t *In, *Out;
    int64_t tm;
    int mapnum = 0;
    int i, j, k;
    int nval, Num_Lines, Line_Length;
    gcm_addr_t gcm_in, gcm_out;
    int64_t nbytes;
    int64_t i64;
    int npoint, numvec;
    int offset;

    if ((res_map = fopen ("res_map", "w")) == NULL) {
        fprintf (stderr, "failed to open file 'res_map'\n");
        exit (1);
        }

    if ((res_cpu = fopen ("res_cpu", "w")) == NULL) {
        fprintf (stderr, "failed to open file 'res_cpu'\n");
        exit (1);
        }

    npoint      = 16;
    numvec      = 16;

    Num_Lines   = npoint*numvec;
    Line_Length = npoint * numvec;


// add dummy line at beginning and end
    nval = (Num_Lines+2) * npoint * numvec;

    In  = malloc (nval * sizeof (int64_t));
    Out = malloc (nval * sizeof (int64_t));

    i = 0;
    for (k=-1; k<Num_Lines+1; k++)  {
    for (j=0; j<Line_Length; j++)  {
        i64 = k*1000 + j;
        In[i] = i64;
        i++;
    }
    }

    if (map_allocate (1)) {
       fprintf (stdout, "Map allocation failed.\n");
       exit (1);
       }

    nbytes = nval * 8;
    gcm_in  = gcm_allocate_by_bank (nbytes, 1);
    gcm_out = gcm_allocate_by_bank (nbytes, 2);

    gcm_cp_to (gcm_in, In, nbytes);

    /* call compute */
    subr (gcm_in, gcm_out, npoint, numvec, Num_Lines, &tm, mapnum);

    printf ("%lld clocks\n", tm);

    gcm_cp_from (gcm_out, Out, nbytes);

    for (k=0; k<Num_Lines; k++)  {
        offset = (k+1)*Line_Length;

    for (j=0; j<Line_Length; j++)  {
        i64 = In[offset + (j%numvec)*npoint+j/numvec];
        fprintf (res_cpu, "%lld\n", i64);
    }
    }

    nval = (Num_Lines) * npoint * numvec;
    for (i=0; i < nval; i++) {
        fprintf (res_map, "%lld\n", Out[i]);
        }

    if (map_free (1)) {
        printf ("Map deallocation failed. \n");
        exit (1);
        }

}

      
