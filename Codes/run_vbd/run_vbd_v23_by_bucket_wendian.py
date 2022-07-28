#!/beegfs/sets/eog/reference/anaconda3/bin/python

import os, re, glob
import sys
import subprocess
import signal
import argparse
from lockfile import FileLock
import findBucket
import calendar, time

vbd_version = '23'
vbd_detect_cmd = 'boats_v'+vbd_version
MCRROOT = '/beegfs/sets/eog/reference/matlab_mcr/v95'
MCRJRE = '/usr/lib/jvm/java/jre/lib/amd64'
REFERENCE = '/beegfs/sets/eog/reference/matlab/vbd_v'

os.environ['MCR_CACHE_ROOT']='/localscratch'

create_input_cmd='/beegfs/sets/eog/reference/bin/vbd_create_input_files_matlab'

smi = '0.035'
si = '0.4'
shi = '0.75'
flare = '500'
moonlit = '0.0001'
strict = '0'
lightning='-1'
ltrim='0'
rtrim='0'
#noise='0,-0.0002,0.3634'
noise=''
boundROI = []
force=False

fileLSM = '/beegfs/sets/eog/reference/vbd_ref/landsea/vbd_landsea_r20170721.mask'
#fileEEZ = '/beegfs/sets/eog/reference/vbd_ref/eez/eez_v9.shp'
fileEEZ = '/beegfs/sets/eog/reference/vbd_ref/eez/eez_v11.shp'
fileFLM = '/beegfs/sets/eog/reference/vbd_ref/VNF-VBD_npp_20120301-20151231_global_asia-enhanced_c201607211230.bitmask'
fileFMZ = '/beegfs/sets/eog/reference/vbd_ref/fmz/WPP_BFAR_merge.shp'
fileMPA = '/beegfs/sets/eog/reference/vbd_ref/mpa/vbd_mpa_r20170830/vbd_mpa_r20170830.shp'
fileLTZ = '/beegfs/sets/eog/reference/vbd_ref/ltz/timezone.shp'
fileRLP = '/beegfs/sets/eog/reference/vbd_ref/VBD_platforms-recurring_2015_r20170330.shp'
fileRLV = '/beegfs/sets/eog/reference/vbd_ref/VBD_bridges_c20160811.shp'
fileTAI = '/beegfs/sets/eog/reference/vbd_ref/lpsec/tai-utc.dat'
fileSAA = '/beegfs/sets/eog/reference/vbd_ref/saa/SAA_zone_2015_a.shp'

poolDir = '/beegfs/sets/eog/nrt/data/incoming/viirs_h5'
default_out_dir = '/beegfs/sets/eog/nrt/data/incoming/vbd_v23/segments'

def preexec_function():
    # Ignore the SIGINT signal by setting the handler to the standard
    # signal handler SIG_IGN.
    signal.signal(signal.SIGINT, signal.SIGKILL)
    
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run VIIRS Nighttime Boat (VBD) detector')

#changed to use bucket -David 2016/03/10
    parser.add_argument('infile1', type=str, help='Input 1st HDF5 file with VIIRS DNB data')
    parser.add_argument('infile2', type=str, help='Input 2nd HDF5 file with VIIRS DNB data')
    parser.add_argument('infile3', type=str, help='Input 3rd HDF5 file with VIIRS DNB data')
    parser.add_argument('infile4', type=str, help='Input 4th HDF5 file with VIIRS DNB data')
    parser.add_argument('--outdir', type=str, help='Name of output directory')
    parser.add_argument('--smi', type=str, help='Spike Median Index (SMI) threshold')
    parser.add_argument('--si', type=str, help='Sharpness Index (SI) threshold')
    parser.add_argument('--shi', type=str, help='Spike Height Index (SHI) threshold')
    parser.add_argument('--flare', type=str, help='Flare (not boat) DNB radiance threshold')
    parser.add_argument('--moonlit', type=str, help='Lunar Illuminance cutoff for constant vs. variable SMI threshold')
    parser.add_argument('--north', type=str, help='ROI north bound')
    parser.add_argument('--east', type=str, help='ROI east bound')
    parser.add_argument('--west', type=str, help='ROI west bound')
    parser.add_argument('--south', type=str, help='ROI south bound')
    parser.add_argument('--strict', type=str, help='Set to 1 to output only high confident boat detections (QF=1)')
    parser.add_argument('--vbdversion', type=str, help='Version of VIIRS Nighttime Boat (VBD) detector')
    parser.add_argument('--version',action='version', version='%(prog)s v'+vbd_version)
    parser.add_argument('--force', dest='simulation',action='store_true')
    parser.add_argument('--trim', dest='simulation',action='store_true')
    parser.add_argument('--lightning', type=str, help='Lightning detector threshold')
    args = parser.parse_args()

    DYLD_LIBRARY_PATH='.:'+MCRROOT+'/runtime/maci64'
    DYLD_LIBRARY_PATH=DYLD_LIBRARY_PATH+':'+MCRROOT+'/bin/maci64'
    DYLD_LIBRARY_PATH=DYLD_LIBRARY_PATH+':'+MCRROOT+'/sys/os/maci64'

    LD_LIBRARY_PATH='.:'+MCRROOT+'/runtime/glnxa64'
    LD_LIBRARY_PATH=LD_LIBRARY_PATH+':'+MCRROOT+'/bin/glnxa64'
    LD_LIBRARY_PATH=LD_LIBRARY_PATH+':'+MCRROOT+'/sys/os/glnxa64'
    LD_LIBRARY_PATH=LD_LIBRARY_PATH+':'+MCRJRE+'/native_threads'
    LD_LIBRARY_PATH=LD_LIBRARY_PATH+':'+MCRJRE+'/server'
    LD_LIBRARY_PATH=LD_LIBRARY_PATH+':'+MCRJRE+'/client'
    LD_LIBRARY_PATH=LD_LIBRARY_PATH+':'+MCRJRE

    dnbname = [args.infile1,args.infile2,args.infile3,args.infile4]
    print('INFO: VIIRS Nighttime Boat detector for DNB bucket files:')
    for i in dnbname:
        print('\t'+i)

    #make bucket list
    tmpDir=default_out_dir
    finder=findBucket.findBucket()
    from random import randint
    import string as s
    rnd_key=''.join([s.ascii_letters[randint(0,51)] for i in range(0,5)])
    bucketList=os.path.join(tmpDir,finder.bucketNumber(dnbname[0])+'_'+rnd_key+'.list')
    writer=open(bucketList,'w')
    for i in dnbname:
        writer.write(os.path.abspath(i+'\n'))
    writer.close()
#    makeList=findBucket.makeList()
#    n_granule=makeList.make(poolDir,dnbname[0],bucketList)

    n_granule=len(dnbname)


#    print(poolDir
#    print(dnbname[0]
#    print(bucketList
#    print(n_granule
    if n_granule != 4:
        print('Incomplete bucket, abort.')
#        if not args.force:
        sys.exit(42)
#        else:
#            'Forced to proceed...'
    
    out_dir = args.outdir
    if out_dir == None:
        out_dir = default_out_dir
        print('INFO: Derived output dir ',out_dir)

    if args.smi != None:
        smi = args.smi
        print('INFO: Forced VBD detector SMI threshold to ',smi)

    if args.si != None:
        si = args.si
        print('INFO: Forced VBD detector SI threshold to ',si)

    if args.shi != None:
        shi = args.shi
        print('INFO: Forced VBD detector SHI threshold to ',shi)

    if args.flare != None:
        flare = args.flare
        print('INFO: Forced VBD detector flare (not boat) DNB radiance threshold to ',smi)

    if args.moonlit != None:
        moonlit = args.moonlit
        print('INFO: Forced moonlit LI threshold to ',moonlit)

    if args.north != None:
        boundROI.extend(['-north',args.north])
        print('INFO: Forced ROI north bound to ',args.north)

    if args.east != None:
        boundROI.extend(['-east',args.east])
        print('INFO: Forced ROI east bound to ',args.east)

    if args.west != None:
        boundROI.extend(['-west',args.west])
        print('INFO: Forced ROI west bound to ',args.west)

    if args.south != None:
        boundROI.extend(['-south',args.south])
        print('INFO: Forced ROI south bound to ',args.south)

    if args.strict != None:
        strict = args.strict
        print('INFO: Forsed VBD strict mode to ',strict)

    if args.vbdversion != None:
        vbd_version = args.vbdversion
        print('INFO: Forced VBD version',vbd_version)

    if args.lightning != None:
        lightning = args.lightning
        print('INFO: Lightting threshold set to',lightning)

    reference_dir = REFERENCE + vbd_version
    
    (fdir,fname) = os.path.split(dnbname[0])
    fprefix = os.path.splitext(fname)[0]
    parts = fprefix.split('_')
    compart = '_'.join(parts[1:6])
    origin = parts[7]
    domain = parts[8]


    #Create input intermediate files for each bucket granule
    bucketFiles=open(bucketList,'r').read().split('\n')
    bucketFiles=[i for i in bucketFiles if i != '']
    bucketFiles.sort()
    retArr=[]
    print('len(bucketFiles)',len(bucketFiles))
    for files in bucketFiles:
        # check lock age
        if os.path.exists(files+'.lock'):
            lock_age=os.path.getmtime(files+'.lock')
            current_time=calendar.timegm(time.gmtime())
            if current_time-lock_age > 1800:
                print('Remove lock older than 1800s: %s' % str(current_time-lock_age))
                os.remove(files+'.lock')
                print('Removed lock file: %s' % files+'.lock')
        with FileLock(files,timeout=1800) as lock:
            ID=re.search('.*(npp.*_b.....).*',files).group(1)
            fileDir=os.path.dirname(files)
            cmdArr=[create_input_cmd,ID,fileDir,'1']
            print(' '.join(cmdArr))

            #ret = subprocess.call(cmdArr, env=dict(os.environ, LD_LIBRARY_PATH=LD_LIBRARY_PATH, DISPLAY=':1'))
            ret = subprocess.call(cmdArr, env=dict(os.environ, LD_LIBRARY_PATH=LD_LIBRARY_PATH))
            if ret != 0:
                print('Input create failed, retry once...')
                ret = subprocess.call(cmdArr, env=dict(os.environ, LD_LIBRARY_PATH=LD_LIBRARY_PATH))
            retArr.append((ret,fileDir))
    fail_flag=0
    for i in retArr:
        if i[0] != 0:
            print('Input create failed:',i[1])
            fail_flag=1
    if fail_flag==1:
        #exit gracefully
        sys.exit(42)


    dtctfile = 'VBD_'+compart+'_'+origin+'_'+domain+'_v'+vbd_version
    dtctname = os.path.join(out_dir,dtctfile).replace('\\','\\\\')
    print('INFO: VBD detect file name',dtctname)
    
    lock_file = dtctfile
    lock_name = os.path.join(out_dir,lock_file).replace('\\','\\\\')
    
    path_detect_cmd = os.path.join(reference_dir,vbd_detect_cmd).replace('\\','\\\\')
    print('INFO: VBD command', path_detect_cmd)
    with FileLock(lock_name, timeout=1800) as lock:
        print('INFO: Lock acquired for',lock_name)

        cmdArr=[path_detect_cmd,bucketList,fileLSM,fileEEZ,fileFLM,'-fmz',fileFMZ,'-ltz',fileLTZ,'-coverage','1','-localmax','1','-mpa',fileMPA,'-rlp',fileRLP,'-rlv',fileRLV,'-tai',fileTAI,'-i05','0','-saa',fileSAA,'-output',out_dir,'-ltrim',ltrim,'-rtrim',rtrim,'-noise',noise]

        cmdArr.extend(boundROI)
        print('VBD Command:')
        print(' '.join(cmdArr))
        #ret = subprocess.call(cmdArr, env=dict(os.environ, LD_LIBRARY_PATH=LD_LIBRARY_PATH, DISPLAY=':1'))
        ret = subprocess.call(cmdArr, env=dict(os.environ, LD_LIBRARY_PATH=LD_LIBRARY_PATH))

        if ret == 0:
            bucketFiles=open(bucketList,'r').read().split('\n')
            bucketFiles=[i for i in bucketFiles if i != '']
            for files in bucketFiles:
                print(files)
                base=os.path.splitext(os.path.basename(files))[0]
                print(base)
                parts = base.split('_')
                newBname = 'VBD_'+'_'.join(parts[1:6])+'_'+'_'.join(parts[7:])+'_v'+vbd_version
                print(newBname)

                kmlDst=os.path.join(out_dir,newBname+'.kml')
                pngDst=os.path.join(out_dir,newBname+'.png')
                csvDst=os.path.join(out_dir,newBname+'.csv')
                if os.path.exists(kmlDst):
                    os.remove(kmlDst)
                if os.path.exists(pngDst):
                    os.remove(pngDst)
                if os.path.exists(csvDst):
                    os.remove(csvDst)
                os.rename(os.path.join(out_dir,base+'.kml'),kmlDst)
                #ret = subprocess.call(['vbd_trim_edges.sh',os.path.join(out_dir,base+'.csv'), csvDst])
                #os.remove(os.path.join(out_dir,base+'.csv'))
                os.rename(os.path.join(out_dir,base+'.csv'),csvDst)
                os.rename(os.path.join(out_dir,base+'.png'),pngDst)
                        
        # Remove temporary bucket list file
        os.remove(bucketList)

        # Give error message for different exit codes & return
        if ret != 0:
            if ret != 42:
                print('ERROR: VBD job has died with exit code',ret)
            else:
                print('WARNING: VBD job did not produce output. Exit code is ',ret)
        else:
            print('INFO: VBD job has finished')

        sys.exit(ret)
