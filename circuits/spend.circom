include "./mimc.circom";

/*
 * IfThenElse sets `out` to `true_value` if `condition` is 1 and `out` to
 * `false_value` if `condition` is 0.
 *
 * It enforces that `condition` is 0 or 1.
 *
 */
template IfThenElse() {
    signal input condition;
    signal input true_value;
    signal input false_value;
    signal output out;

    // TODO
    // Hint: You will need a helper signal...

    out <== condition*true_value + (1-condition)*false_value;
}

/*
 * SelectiveSwitch takes two data inputs (`in0`, `in1`) and produces two ouputs.
 * If the "select" (`s`) input is 1, then it inverts the order of the inputs
 * in the ouput. If `s` is 0, then it preserves the order.
 *
 * It enforces that `s` is 0 or 1.
 */
template SelectiveSwitch() {
    signal input in0;
    signal input in1;
    signal input s;
    signal output out0;
    signal output out1;

    // if s == 1, then swap the inputs
    // if s == 0, then keep the inputs
    signal mux;
    mux <== (in0 - in1)*s;
    out0 <== in0 - mux;
    out1 <== in1 + mux;
}

/*
 * Verifies the presence of H(`nullifier`, `nonce`) in the tree of depth
 * `depth`, summarized by `digest`.
 * This presence is witnessed by a Merle proof provided as
 * the additional inputs `sibling` and `direction`, 
 * which have the following meaning:
 *   sibling[i]: the sibling of the node on the path to this coin
 *               at the i'th level from the bottom.
 *   direction[i]: "0" or "1" indicating whether that sibling is on the left.
 *       The "sibling" hashes correspond directly to the siblings in the
 *       SparseMerkleTree path.
 *       The "direction" keys the boolean directions from the SparseMerkleTree
 *       path, casted to string-represented integers ("0" or "1").
 */
template Spend(depth) {
    signal input digest;
    signal input nullifier;

    signal private input nonce;
    signal private input sibling[depth];
    signal private input direction[depth];

    // TODO

    component hasher = Mimc2();
    hasher.in0 <== 0;
    hasher.in1 <== nullifier + nonce;

    signal leaf ;
    leaf <== hasher.out;

    component mux[depth];
    component multiMimc7[depth];

    // sparse merkle tree
    for (var i = 0; i < depth; i++) {
        mux[i] = SelectiveSwitch();
        mux[i].in0 <== i==0 ? leaf : multiMimc7[i-1].out;
        mux[i].in1 <== sibling[i];
        mux[i].s <== direction[i];

        multiMimc7[i] = MultiMimc7(2,224);
        multiMimc7[i].in[0] <== mux[i].out0;
        multiMimc7[i].in[1] <== mux[i].out1;
        multiMimc7[i].k <== 0;

    }

    multiMimc7[depth-1].out === digest;


}
