# MEX='/usr/local/matlab/bin/mex'
# MEX='/home/wangcf/Softwares/MATLAB/bin/mex'
MEX='/picb/extprog/inst/matlab/matlab-r2007b/bin/mex'
# MEX='E:\matlab\bin\mex.bat'
CC='/usr/bin/gcc'
# CC='D:\Batch\MingW\bin\gcc'
OPT='/picb/extprog/inst/matlab/matlab-r2007b/bin/gccopts.sh'

all : 	ml_texture 	ml_moments_1 	ml_tclread 	ml_majfilt 	ml_createfile_excl

# ${MEX} -v -DPI#M_PI -f /usr/local/matlab/bin/cxxopts.sh ml_Znl.cpp
#ml_Znl : ml_Znl.cpp
#	${MEX} -v -DPI#M_PI -f ${OPT} ml_Znl.cpp

ml_texture : ml_texture.c cvip_pgmtexture.o 
	${MEX} ml_texture.c cvip_pgmtexture.o

cvip_pgmtexture.o : cvip_pgmtexture.c
	gcc -c -IInclude -ansi cvip_pgmtexture.c

ml_moments_1 : ml_moments_1.c
	${MEX} ml_moments_1.c

ml_tclread : ml_tclread.cpp
	${MEX}  ml_tclread.cpp

mv_majfilt: mv_majfilt.c
	${MEX} -D_MEX_ mv_majfilt.c

ml_createfile_excl: ml_createfile_excl.c
	${CC} -o ml_createfile_excl ml_createfile_excl.c
