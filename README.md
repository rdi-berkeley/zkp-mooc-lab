# Assignment: Writing and Proving Arithmetic Circuits

In this assignment you’ll learn about:
* `circom`: a domain-specific language for describing arithmetic circuits, and
* `snarkjs`: a tool for generating and verifying zk-SNARKs for circuit satisfiability.

# Setup

1. Install [nodejs](https://nodejs.org/en/download/) (includes `npm`).
2. Install `circom` following this [installation guide](https://docs.circom.io/getting-started/installation/). Once installed, ensure that you're using the correct version of `circom` by running `circom --version`. You should see `circom compiler 2.1.4` or later.
3. Install `snarkjs`: run `npm install -g snarkjs@latest`.
4. Install the `mocha test runner`: run `npm install -g mocha`.
5. Run `npm install` in the same directory as this readme to install the dependencies for this assignment.
6. Run `mocha test` and verify that most of the tests fail, but not because of missing dependencies.

# Assignment Details

## Task 1: Implement a (simplified) floating-point addition circuit in `circom`

In this task, you'll be implementing a (simplified) floating-point addition circuit in `circom`. **This task does not assume any familiarity with floating-point arithmetic and you are not required to understand floating-point addition to complete it**.  
Before you begin, please go through the [circom documentation](https://docs.circom.io/circom-language/signals/) and `circuits/example.circom`.

**The `src/` directory has a python program `float_add.py` that implements the floating-point addition logic. Use this file as a reference point for the set of instructions you have to translate into a circuit**. We have added minimal comments in `float_add.py` as they can be distracting. For curious students, we've added another file `src/float_add_with_comments.py` that implements the same logic and has extensive comments explaining the floating-point representation and the addition algorithm.

**The `circuits/` directory has a file `float_add.circom` that contains the skeleton of the circuit that you have to complete**.
We've broken down the circuit into several templates such that each function in `float_add.py` has a corresponding template in `float_add.circom`.
Each template has comments explaining its inputs and outputs, as well as any conditions that have to be enforced by that template.
**You have to implement the empty templates one-by-one in the order they appear in the file**. You can independently test each template by running `mocha test/[template_name_in_snake_case].js`. **There's partial credit for each template**.
Some useful templates are already implemented in `float_add.circom` for you to use in your circuit and to serve as examples.

`circom` will compile your circuits to a Rank-1 Constraint System (R1CS) instance (see Lecture 3 for definition), the primary efficiency metric for which is the number of constraints (fewer is better). You can find the number of constraints in your implementation using the testing suite. The suite also tells you the number of constraints expected from an optimized circuit implementation. **There's bonus points if the number of constraints in your implementation are close to the optimized constraints**.

> **Deliverable**: completed `float_add.circom`

## Task 2: Generate a zk-SNARK proof using `snarkjs`

In this task, you will use `snarkjs` to generate a `Groth16` proof that proves $7 \times 17 \times 19 = 2261$ using the `SmallOddFactorization` circuit implemented in `circuits/example.circom`.
Follow the steps in `snarkjs` [README](https://github.com/iden3/snarkjs) until Step 24, and you will learn how to create a `Groth16` proof and verify it. You can use the `powersOfTau28_hez_final_08.ptau` file in the root directory of this assignment to skip the first 9 steps.

> **Deliverable**: `proof.json` and `verification_key.json` generated while following the proof generation steps.

# Testing

We’ve provided a few unit tests for the various components you have to implement to test their correctness. You can run all the tests using `mocha test`.

The unit tests **only check correctness of your constraint system**, i.e., the constraints are satisfied given a valid witness. They **do not check the soundness of your system**, i.e., for all invalid witnesses, the constraints are not satisfied. **To get full credit, your circuit has to be correct as well as sound**.

As a sanity check, the test suite also checks the number of constraints in your circuits, and throws a warning if that number is smaller than expected. If there's a warning, it is likely that you're not appropriately constraining all the signals, and thus, your system is not sound.

# Submission

Use the submission link on the course webpage to submit the deliverables (i.e., `float_add.circom`, `proof.json`, and `verification_key.json`) in a zip file.
