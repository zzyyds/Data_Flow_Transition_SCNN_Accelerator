#!/bin/bash

	# Compare index
	diff "out_data.txt" "output_activations_truth.txt" &> comp_result.txt
	ret=$?

	if [[ $ret -eq 0 ]]; then
		echo "========= out_data Passed ========="
	else
		echo "========= out_data Failed ========="
		exit 0
	fi


	# Compare data
	diff "out_indices.txt" "output_indices_truth.txt" &> ../comp_result_indices.txt
	ret=$?

	if [[ $ret -eq 0 ]]; then
		echo "========= out_indices Passed ========="
	else
		echo "========= out_indices Failed ========="
		exit 0
	fi

    

	
   

    
