













































































































































































































































































































































































































































































perl sew.pl sew.md weave '#baseline' || {
    echo "Err: sew.pl failed" 1>&2
    exit 1
}

diff baseline.md.md baseline.weave || { 
    echo "Err: baseline test failed" 1>&2
    exit 1
    }



