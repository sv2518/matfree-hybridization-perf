#!/bin/sh

# source /Users/sv2518/firedrakeinstalls/fresh/firedrake/bin/activate
# cd /Users/sv2518/firedrakeexamples/mathybperf/mathybperf/performance

# turn off threading
export OMP_NUM_THREADS=1

# setup (MAKE YOUR CHANGES HERE)
ARG0="$1"
current_case="$ARG0"
my_dir="$(dirname "$0")"
echo "MYDIR"
echo $my_dir
pwd
ls
. setups/$current_case.sh

# mode of the script, options are:
# do we want to generate a tex from this?
# do we want to generate new results?
ARG1="$3"
ARG2="$4"
ARG3="$5"
if [[ "$ARG1" == "--nores" || "$ARG2" == "--nores" || "$ARG3" == "--nores" ]]
then
    DORES=false
else
    DORES=true
fi
if [[ "$ARG1" == "--tex" || "$ARG2" == "--tex" || "$ARG3" == "--tex" ]]
then
    DOTEX=true
else
    DOTEX=false
fi
if [[ "$ARG1" == "--verification" || "$ARG2" == "--verification" || "$ARG3" == "--verification" ]]
then
    VERIFICATION=--verification
    # For verification of the performance runs we need to
    # project the exact solutions to get some errors.
    # It's sufficient to get error in one state (we test the cool state).
    PROJECTEXACTSOL=--projectexactsol
    # Projecting the solutions will slow down the runs,
    # but for verification we don't care for performance.
    # Hence no flamegraphs will be generated.
    FLAME=false
    ORDERS=("$2")
fi


# setup output folder name
# first choose a case name
if ! [ "$VERIFICATION" == "--verification" ]
then
    FOLDER='results/mixed_poisson/'
else
    FOLDER='verification/results/mixed_poisson/'
fi
FOLDER+='pplus1pow3/'  # penalty set permanently to this
TRAFOTYPE='trafo_'$TRAFO'/'
BASENAME=$FOLDER$CASE$TRAFOTYPE
FLAMEBASENAME='flames/mixed_poisson/pplus1pow3/'$CASE$TRAFOTYPE
LINKS=""
CURLS=""
WEBPAGE="https://raw.githubusercontent.com/sv2518/mathybperf/main/mathybperf/performance/"
CURRENT_BRANCH=$(git branch --show-current)

alias urlencode='python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'
if $DORES
then
    # file name is parameter set name
    for D in "${DEFORM[@]}"
    do
        for S in "${SCALING[@]}"
        do
            for P in "${ORDERS[@]}"
            do
                for C in "${CELLSPD[@]}"
                do
                    NAME=$BASENAME"order_"$P"/cells_"$C"/"
                    mkdir -p $NAME
                    FLAMENAME=$FLAMEBASENAME"order_"$P"/cells_"$C"/"
                    CURLS=$CURLS"mkdir -p "$FLAMENAME"\n"
                    LINKS=$LINKS'\n\nLinks for flames of RT$_{p+1}$-DG$_{p}$ with $p='$P'$ and base mesh $'$C'\\times'$C'\\times'$C'$ refined on '$LEVELS' levels\\\\ \n\n'
                    if ! $FLAME
                    then
                        FLARG=''
                    else
                        mkdir -p $FLAMENAME
                    fi

                    # run base case
                    PARAMS=$BASEP
                    NNAME=$NAME$PARAMS
                    FNAME=$FLAMENAME$PARAMS
                    if ! [ "$VERIFICATION" == "--verification" ]
                    then
                        firedrake-clean
                    fi
                    NNAME+='_warm_up'
                    FNAME+='_warm_up'
                    reftochap='\\caseRT'$((P+1))"DG"$P
                    LINKS=$LINKS"Extra info for following runs see \hyperref[setup"$reftochap"]{setup"$reftochap"} and \hyperref[solverbase"$reftochap"]{solverbase"$reftochap"}\n\n"
                    
                    LINKS=$LINKS"Baseline warmup run\n"
                    if $FLAME
                    then
                        FLARG='-log_view :'$FNAME'_flame.txt:ascii_flamegraph'
                    fi
                    python3 run_profiler.py $NNAME $PARAMS $P $LEVELS $QUADS $S $D $TRAFO $C $SOLTYPE $FLARG --add_to_quad_degree "${ATQD[@]}" --clean  $PROJECTEXACTSOL $VERIFICATION > $NNAME"_log.txt"
                    retcode=$?

                    if ! [ "$VERIFICATION" == "--verification" ]
                    then
                        if $FLAME
                        then
                        ../../../FlameGraph/flamegraph.pl $FNAME"_flame.txt" > $FNAME"_flame.svg"  --inverted --title "Firedrake example" --countname us --fontsize 13 --colors "eyefriendly"
                        fi
                        # Make new flamegraphs online accessible
                        git add $FLAMENAME*"_flame.svg"
                        git add -f $FLAMENAME*"_flame.txt"
                        git commit -m "New flamegraphs were generated for parameter sets "$BASEP" and "$PERFORMP"."
                        # git push origin $CURRENT_BRANCH
                        # Generate data for links
                        long_url="https://www.speedscope.app/#profileURL="$WEBPAGE$FNAME"_flame.txt"
                        encode_long_url=$(urlencode $long_url)
                        short_url=$(curl -s "http://tinyurl.com/api-create.php?url=${encode_long_url}")
                        LINKS=$LINKS"\url{$short_url}\n\n"
                        CURLS=$CURLS"curl "$WEBPAGE$FNAME"_flame.svg>"$FNAME"_flame.svg\n"

                        NNAME=$NAME$PARAMS
                        FNAME=$FLAMENAME$PARAMS
                        NNAME+='_warmed_up'
                        FNAME+='_warmed_up'
                        LINKS=$LINKS"Baseline warmed up run\n"
                        if $FLAME
                        then
                            FLARG='-log_view :'$FNAME'_flame.txt:ascii_flamegraph'
                        fi
                        python3 run_profiler.py $NNAME $PARAMS $P $LEVELS $QUADS $S $D $TRAFO $C $SOLTYPE $FLARG --add_to_quad_degree "${ATQD[@]}" $PROJECTEXACTSOL $VERIFICATION > $NNAME"_log.txt"
                        # run for counting flops seperate in order to not screw up the performance
                        # export PYOP2_COMPUTE_KERNEL_FLOPS=0
                        # export PYOP2_DUMP_SLATE_FLOPS=$NNAME'_slate_flops.txt'
                        # python3 run_profiler.py $NNAME $PARAMS $P $LEVELS $QUADS $S $D $TRAFO $C $SOLTYPE --add_to_quad_degree "${ATQD[@]}" $PROJECTEXACTSOL $VERIFICATION -log_view :$NNAME'_full_flops.txt'
                        # export PYOP2_COMPUTE_KERNEL_FLOPS=0
                        # export PYOP2_DUMP_SLATE_FLOPS=""
                    
                        if $FLAME
                        then
                        ../../../FlameGraph/flamegraph.pl $FNAME"_flame.txt" > $FNAME"_flame.svg"  --inverted --title "Firedrake example" --countname us --fontsize 13 --colors "eyefriendly"
                        fi
                        # Make new flamegraphs online accessible
                        git add $FLAMENAME*"_flame.svg"
                        git add -f $FLAMENAME*"_flame.txt"
                        git commit -m "New flamegraphs were generated for parameter sets "$BASEP" and "$PERFORMP"."
                        # git push origin $CURRENT_BRANCH
                        # Generate data for links
                        long_url="https://www.speedscope.app/#profileURL="$WEBPAGE$FNAME"_flame.txt"
                        encode_long_url=$(urlencode $long_url)
                        short_url=$(curl -s "http://tinyurl.com/api-create.php?url=${encode_long_url}")
                        LINKS=$LINKS"\url{$short_url}"'\\\\\n\n'
                        CURLS=$CURLS"curl "$WEBPAGE$FNAME"_flame.svg>"$FNAME"_flame.svg\n"
                    else
                        if [ $retcode == 1 ]
                        then
                            exit 1
                        fi
                    fi

                    # run perf case
                    PARAMS=$PERFORMP
                    NNAME=$NAME$PARAMS
                    FNAME=$FLAMENAME$PARAMS
                    if ! [ "$VERIFICATION" == "--verification" ]
                    then
                        firedrake-clean
                    fi
                    NNAME+='_warm_up'
                    FNAME+='_warm_up'
                    reftochap='\\caseRT'$((P+1))"DG"$P
                    LINKS=$LINKS"Extra info for following runs see \hyperref[setup$reftochap]{setup$reftochap} and \hyperref[solverperf"$reftochap"]{solverperf"$reftochap"}\n\n"
                    LINKS=$LINKS"Performance warmup run\n"
                    if $FLAME
                    then
                        FLARG='-log_view :'$FNAME'_flame.txt:ascii_flamegraph'
                    fi
                    echo  $NNAME"_log.txt"
                    if ! [ "$VERIFICATION" == "--verification" ]
                    then
                        firedrake-clean
                    fi
                    python3 run_profiler.py $NNAME $PARAMS $P $LEVELS $QUADS $S $D $TRAFO $C $SOLTYPE $FLARG --add_to_quad_degree "${ATQD[@]}" --clean $PROJECTEXACTSOL $VERIFICATION > $NNAME"_log.txt"
                    retcode=$?

                    if ! [ "$VERIFICATION" == "--verification" ]
                    then
                        if $FLAME
                        then
                        ../../../FlameGraph/flamegraph.pl $FNAME"_flame.txt" > $FNAME"_flame.svg"  --inverted --title "Firedrake example" --countname us --fontsize 13 --colors "eyefriendly"
                        fi
                        # Make new flamegraphs online accessible
                        git add $FLAMENAME*"_flame.svg"
                        git add -f $FLAMENAME*"_flame.txt"
                        git commit -m "New flamegraphs were generated for parameter sets "$BASEP" and "$PERFORMP"."
                        # git push origin $CURRENT_BRANCH
                        # Generate data for links
                        long_url="https://www.speedscope.app/#profileURL="$WEBPAGE$FNAME"_flame.txt"
                        encode_long_url=$(urlencode $long_url)
                        short_url=$(curl -s "http://tinyurl.com/api-create.php?url=${encode_long_url}")
                        LINKS=$LINKS"\url{$short_url}\n\n"
                        CURLS=$CURLS"curl "$WEBPAGE$FNAME"_flame.svg>"$FNAME"_flame.svg\n"

                        NNAME=$NAME$PARAMS
                        FNAME=$FLAMENAME$PARAMS
                        NNAME+='_warmed_up'
                        FNAME+='_warmed_up'
                        LINKS=$LINKS"Performance warmed up run\n"
                        if $FLAME
                        then
                            FLARG='-log_view :'$FNAME'_flame.txt:ascii_flamegraph'
                        fi
                        python3 run_profiler.py $NNAME $PARAMS $P $LEVELS $QUADS $S $D $TRAFO $C $SOLTYPE $FLARG --add_to_quad_degree "${ATQD[@]}" $PROJECTEXACTSOL > $NNAME"_log.txt"
                        # run for counting flops seperate in order to not screw up the performance
                        # export PYOP2_COMPUTE_KERNEL_FLOPS=0
                        # export PYOP2_DUMP_SLATE_FLOPS=$NNAME'_slate_flops.txt'
                        # python3 run_profiler.py $NNAME $PARAMS $P $LEVELS $QUADS $S $D $TRAFO $C $SOLTYPE --add_to_quad_degree "${ATQD[@]}" $PROJECTEXACTSOL $VERIFICATION -log_view :$NNAME'_flops.txt'
                        # export PYOP2_COMPUTE_KERNEL_FLOPS=0
                        # export PYOP2_DUMP_SLATE_FLOPS=""

                        if $FLAME
                        then
                        ../../../FlameGraph/flamegraph.pl $FNAME"_flame.txt" > $FNAME"_flame.svg"  --inverted --title "Firedrake example" --countname us --fontsize 13 --colors "eyefriendly"
                        fi
                        # Make new flamegraphs online accessible
                        git add $FLAMENAME*"_flame.svg"
                        git add -f $FLAMENAME*"_flame.txt"
                        git commit -m "New flamegraphs were generated for parameter sets "$BASEP" and "$PERFORMP"."
                        # git push origin $CURRENT_BRANCH
                        # Generate data for links
                        long_url="https://www.speedscope.app/#profileURL="$WEBPAGE$FNAME"_flame.txt"
                        encode_long_url=$(urlencode $long_url)
                        short_url=$(curl -s "http://tinyurl.com/api-create.php?url=${encode_long_url}")
                        LINKS=$LINKS'\url{'$short_url'}\\\\\n'
                        CURLS=$CURLS"curl "$WEBPAGE$FNAME"_flame.svg>"$FNAME"_flame.svg\n"
                    else
                        if ! [ $retcode == 0 ]
                        then
                            echo "WE have a problem"
                            exit 1
                        fi
                    fi
                done
            done
        done
    done
fi


if ! [ "$VERIFICATION" == "--verification" ]
then
    # Keep track of the sh file
    SCRIPT="run_profiler.sh"
    cp $SCRIPT $BASENAME"backup_of_"$SCRIPT

    # Generate and publish script to fetch the svg files
    touch $FLAMEBASENAME"curlthesvgs.sh"
    echo "#!/bin/sh\nmkdir -p ./svgs/"$FLAMEBASENAME"\ncd svgs\n"$CURLS"\n" > $FLAMEBASENAME"curlthesvgs.sh"
    git add $FLAMEBASENAME"curlthesvgs.sh"
    git commit -m "New script to fetch flamegraphs was generated."
    CURRENT_BRANCH=$(git branch --show-current)
    # git push origin $CURRENT_BRANCH
fi

if $DOTEX
then
    # System and Firedrake information
    system_profiler -detailLevel mini SPSoftwareDataType SPHardwareDataType > "./"$FOLDER$CASE"systeminfo.txt"
    firedrake-status > "./"$FOLDER$CASE"firedrakestatus.txt"

    # Save the links to the svgs in a file for easy access from the report
    # but a note that explain how to fetch this automatically to a local repo
    NOTE="\nIf you want the flamegraphs locally as svgs just run\n\ncurl -OL "$WEBPAGE$FLAMEBASENAME"curlthesvgs.sh\n\n and then\n\nsh ./curlthesvgs.sh."
    touch $FOLDER$CASE"linkstosvgs.tex"
    echo $LINKS"\n"$NOTE > $FOLDER$CASE"linkstosvgs.tex"

    # Move results over into report directory and push online
    PATH_TO_REPORT='../../../mathybperf_report/61dc091dbf10034613ed0daa/'
    find ./$FOLDER -type f | grep -i setup.tex$ | xargs -I{} ditto {} $PATH_TO_REPORT/{}
    find ./$FOLDER -type f | grep -i log.txt$ | xargs -I{} ditto {} $PATH_TO_REPORT/{}
    find ./$FOLDER -type f | grep -i parameters.txt$ | xargs -I{} ditto {} $PATH_TO_REPORT/{}
    find ./$FOLDER -type f | grep -i extradata.tex$ | xargs -I{} ditto {} $PATH_TO_REPORT/{}
    find ./ -type f | grep -i systeminfo.txt$ | xargs -I{} ditto {} $PATH_TO_REPORT/{}
    find ./ -type f | grep -i firedrakestatus.txt$ | xargs -I{} ditto {} $PATH_TO_REPORT/{}
    find ./ -type f | grep -i linkstosvgs.tex$ | xargs -I{} ditto {} $PATH_TO_REPORT/{}
    find ./$FOLDER -type f | grep -i setup.tex$ | xargs -I{} git -C $PATH_TO_REPORT add {} 
    find ./$FOLDER -type f | grep -i log.txt$ | xargs -I{} git -C $PATH_TO_REPORT add {} 
    find ./$FOLDER -type f | grep -i parameters.txt$ | xargs -I{} git -C $PATH_TO_REPORT add {}
    find ./$FOLDER -type f | grep -i extradata.tex$ | xargs -I{} git -C $PATH_TO_REPORT add {}
    find ./ -type f | grep -i systeminfo.txt$ | xargs -I{} git -C $PATH_TO_REPORT add {}
    find ./ -type f | grep -i firedrakestatus.txt$ | xargs -I{} git -C $PATH_TO_REPORT add {}
    find ./ -type f | grep -i linkstosvgs.tex$ | xargs -I{} git -C $PATH_TO_REPORT add {}
    git -C $PATH_TO_REPORT commit -m "New results"
    git -C $PATH_TO_REPORT pull origin master
    git -C $PATH_TO_REPORT push origin master
fi
