#!/bin/sh
mkdir -p ./svgs/
cd svgs
mkdir -p flames/mixed_poisson/pplus1pow3/trafo_none/case2/order_0/cells_3/
curl https://raw.githubusercontent.com/sv2518/mathybperf/main/mathybperf/performance/flames/mixed_poisson/pplus1pow3/trafo_none/case2/order_0/cells_3/jacks_baseline_params_nested_schur_warm_up_flame.svg>flames/mixed_poisson/pplus1pow3/trafo_none/case2/order_0/cells_3/jacks_baseline_params_nested_schur_warm_up_flame.svg
curl https://raw.githubusercontent.com/sv2518/mathybperf/main/mathybperf/performance/flames/mixed_poisson/pplus1pow3/trafo_none/case2/order_0/cells_3/jacks_baseline_params_nested_schur_warmed_up_flame.svg>flames/mixed_poisson/pplus1pow3/trafo_none/case2/order_0/cells_3/jacks_baseline_params_nested_schur_warmed_up_flame.svg
curl https://raw.githubusercontent.com/sv2518/mathybperf/main/mathybperf/performance/flames/mixed_poisson/pplus1pow3/trafo_none/case2/order_0/cells_3/perform_params_local_mat_warm_up_flame.svg>flames/mixed_poisson/pplus1pow3/trafo_none/case2/order_0/cells_3/perform_params_local_mat_warm_up_flame.svg
curl https://raw.githubusercontent.com/sv2518/mathybperf/main/mathybperf/performance/flames/mixed_poisson/pplus1pow3/trafo_none/case2/order_0/cells_3/perform_params_local_mat_warmed_up_flame.svg>flames/mixed_poisson/pplus1pow3/trafo_none/case2/order_0/cells_3/perform_params_local_mat_warmed_up_flame.svg


