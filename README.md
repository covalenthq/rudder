# Rudder

Rudder is the rule engine processor and supervisor for the refiner process in the Covalent Network and further it scalably and securely captures block specimens and their respective transformations. It listens for events on ProofChain for finalized block specimens which further get processed into block results, uploaded to IPFS and the proof of the job performed gets submitted to the ProofChain.

![Rudder Pipeline](./temp/Rudder.jpg)

The happy path for `rudder` is made up of loosely coupled (some maintain state and some don't) actor processes, that can be called upon to fulfill responsiblities at different sections in the refinement/transformation process - under one umberalla supervisor process, that can bring them back up in case of a failure.

## Rudder Pipeline Components Explained

### Block Specimen Proof Event and Block Result Proof Event Listeners

The listeners watch the ProofChain for Block Specimen Proof (BSP) sessions to be finalized and for Block Result Proof (BRP) sessions to be started. In the first case once a BSP session is finalized the BSP Listener pulls all the `storageURLs` for the winning `specimenHash`. In case of listening for BRP sessions, once someone starts a Block Result Proof session, the BRP Listener pulls the specimen hash for which the BRP was submitted. Further the specimen hashes and storage URLs are passed to Block Specimen Discovery.

 1. **BlockSpecimenProofEventListener** listens for the following events:
 ```
 event BlockSpecimenProductionProofSubmitted(
        uint64 chainId,
        uint64 blockHeight,
        bytes32 blockHash,
        bytes32 specimenHash,
        string storageURL, // URL of specimen storage
        uint128 submittedStake
    );
 ```
 and 
 ```
 event BlockSpecimenRewardAwarded(
        uint64 indexed chainId, 
        uint64 indexed blockHeight, 
        bytes32 indexed blockhash, 
        bytes32 specimenhash
     );
 ```
 
 2. **BlockResultProofEventListener** listens for:
 ```
 event BlockResultProductionProofSubmitted(
        uint64 chainId, 
        uint64 blockHeight,
        bytes32 specimenHash, 
        bytes32 resultHash, 
        string storageURL, 
        uint128 submittedStake
      );
```

### Work Item Generation Supervisor
Once an event listener pushes a specimen hash to Work Item Generation Supervisor it would spawn the Work Item Generation Pipeline process for the given specimen. Currently this is just an idea and the listeners can directly spawn the Pipeline witout a supervisor, but would be logically correct?

### Work Item Generation Pipeline
The idea is that it would run in one process that takes the specimen hash and outputs a work item. The following steps need to be done:
1. A specimen hash would be pushed to the **Block Specimen Discoverer** that would pull the actual specimen based on its hash either from local storage or IPFS. 
2. The specimen comes in `avro` format and needs to be converted to `json'. This is done by the **Block Specimen Decoder**. 
3. **Work Item Factory** checks for the latest job blueprint and attaches it together withe specimen. The job blueprint will need to be provided to the Block Processor (Processing Engine) which is done later in another process. 


### Work Items Queue 
This would contain all the work items that are waiting to be processed. This won't be implemented in the initial version.

### Scheduler
This would track what work items have been processed and push new work items from the Queue into the Block Processor. This won't be implemented in the initial version.

### Block Processor
**Block Processor** is the engine that takes block specimen with a blueprint as input and converts it into a trace/block result. 

### Block Result Uploader 
This is another process that would upload the whole Trace / Block Result to IPFS then generated its' hash and upload it to the ProofChain. 

## Install

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rudder` to your list of dependencies in `mix.exs`:

  ```elixir
    def deps do
      [
        {:rudder, "~> 0.1.0"}
      ]
    end
  ```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/rudder>.

## Block Specimen Transformer (using `Go` binary)

1. Check if the transformer plugin exists.

  ```bash
    cd rudder/evm
    drwxr-xr-x   3 pranay  staff        96 Oct  4 10:33 .
    drwxr-xr-x  28 pranay  staff       896 Oct  5 11:59 ..
    -rwxr-xr-x   1 pranay  staff  17503704 Oct  4 10:33 extractor
  ```

2. Start application and apply transform rules.

  ```elixir
    iex -S mix

    Erlang/OTP 25 [erts-13.0] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit:ns] [dtrace]
    Generated rudder app
    Interactive Elixir (1.13.4) - press Ctrl+C to exit (type h() ENTER for help)

 iex(3)> Rudder.build_sync("rules/rules.json")
%{
  "args" => "--binary-file-path './test-data/' --codec-path './priv/schemas/block-ethereum.avsc' --indent-json 0 --output-file-path './out/block-results/'",
  "exec" => "./evm/extractor",
  "input" => "./bin/block-specimens/",
  "output" => "./out/block-results/",
  "rule" => "./evm/extractor --binary-file-path './test-data/' --codec-path './priv/schemas/block-ethereum.avsc' --indent-json 0 --output-file-path './out/block-results/'"
}
%Porcelain.Result{
  err: nil,
  out: "bsp-extractor command line config:  [binary-file-path:\"./test-data/\" codec-path:\"./priv/schemas/block-ethereum.avsc\" indent-json:\"0\" output-file-path:\"./out/block-results/\"]\n\nfile:  out/block-results/1-15127599-replica-0x167a4a9380713f133aa55f251fd307bd88dfd9ad1f2087346e1b741ff47ba7f5-specimen.json bytes:  1563265\n\nfile:  out/block-results/1-15127600-replica-0x14a2d5978dcde0e6988871c1a246bea31e44f73467f7c242f9cd19c30cd5f8b1-specimen.json bytes:  2761078\n\nfile:  out/block-results/1-15127601-replica-0x4757d9272c0f4c5f961667d43265123d22d7459d63f2041866df2962758c6070-specimen.json bytes:  3693996\n\nfile:  out/block-results/1-15127602-replica-0xce9ed851812286e05cd34684c9ce3836ea62ebbfc3764c8d8a131f0fd054ca35-specimen.json bytes:  4492753\n\nfile:  out/block-results/1-15127603-replica-0x5fb7802a8b0f1853bd3e9e8a8646df603e6c57d8da7df62ed46bfec1a6a074c4-specimen.json bytes:  1684665\n",
  status: 0
}
  ```

This should generate the JSON output specimen file (results) to `./out` directory as seen above.

3. View generated/transformed files from binary block specimens

  ```bash
    cd out/block-results
    cat 1-15127599-replica-0x167a4a9380713f133aa55f251fd307bd88dfd9ad1f2087346e1b741ff47ba7f5-specimen.json
  ```

## Block Specimen Extractor (`Elixir` native)

1. In the above process we used a sync method to extract all the files in a given directory using a binary generated by Go code

2. Here we extract the files directly async by using a file stream, spawing a decode process for each file separately and using the AVRO library `avrora`

3. It is tested internally with the following steps ()
  a. reads a binary block specimen file
  b. starts the avro client
  c. decodes to json map using the `decode_plain` avrora fn
  d. streams the binary files (does it async - during stream execution)

```elixir

iex(4)> iex(3)> Rudder.Avro.BlockSpecimenDecoder.decode_file("test-data/1-15127599-replica-0x167a4a9380713f133aa55f251fd307bd88dfd9ad1f2087346e1b741ff47ba7f5")
[debug] reading schema `block-ethereum` from the file /Users/pranay/Documents/covalent/elixir-projects/rudder/priv/schemas/block-ethereum.avsc
{:ok,
 %{
   "codecVersion" => 0.2,
   "elements" => 1,
   "endBlock" => 15127599,
   "replicaEvent" => [
     %{
       "data" => %{
         "Hash" => "0x8f858356c48b270221814f8c1b2eb804a5fbd3ac7774b527f2fe0605be03fb37",
         "Header" => %{
           "baseFeePerGas" => 14761528828.0,
           "difficulty" => 1.1506847309002466e16,
           "extraData" => "SGl2ZW9uIHVzLWhlYXZ5",
           "gasLimit" => 29999972,
           ...
           ..
           .
           
```

4. Please note the above extractor process only extract a single specimen


```elixir

iex(6)> Rudder.Avro.BlockSpecimenDecoder.decode_dir("test-data/*")
[
  #Stream<[
    enum: ["test-data/1-15127599-replica-0x167a4a9380713f133aa55f251fd307bd88dfd9ad1f2087346e1b741ff47ba7f5"],
    funs: [#Function<47.127921642/1 in Stream.map/2>]
  ]>,
  #Stream<[
    enum: ["test-data/1-15127600-replica-0x14a2d5978dcde0e6988871c1a246bea31e44f73467f7c242f9cd19c30cd5f8b1"],
    funs: [#Function<47.127921642/1 in Stream.map/2>]
  ]>,
  #Stream<[
    enum: ["test-data/1-15127601-replica-0x4757d9272c0f4c5f961667d43265123d22d7459d63f2041866df2962758c6070"],
    funs: [#Function<47.127921642/1 in Stream.map/2>]
  ]>,
  #Stream<[
    enum: ["test-data/1-15127602-replica-0xce9ed851812286e05cd34684c9ce3836ea62ebbfc3764c8d8a131f0fd054ca35"],
    funs: [#Function<47.127921642/1 in Stream.map/2>]
  ]>,
  #Stream<[
    enum: ["test-data/1-15127603-replica-0x5fb7802a8b0f1853bd3e9e8a8646df603e6c57d8da7df62ed46bfec1a6a074c4"],
    funs: [#Function<47.127921642/1 in Stream.map/2>]
  ]>
]

```

5. A stream of specimens files can be passed instead to the avro decode process for lazy eval and further down the pipeline to the EBE (erigon t8n tool) processor

## Block Specimen Session Event Listener

In order to run the listener you need to fork ethereum node, run a script to add the operators and a script that mocks block specimen submissions and session finalizations using the docker:

1. Add `.env` file.

2. Inside `.env` add ERIGON_NODE variable and replace the node's url with yours:

```bash
export ERIGON_NODE="erigon.node.url"
```

3. Inside a terminal got to the rudder folder and run: 

```bash
docker compose --env-file ".env" -f "docker-compose-local.yml" up --remove-orphans
```

4. Inside a separate terminal run:

```bash
docker exec -it eth-node /bin/sh  -c "cd /usr/src/app; npm run docker:run";
```

5. Inside a third terminal navigate to the `rudder` folder and run:

```elixir
iex -S mix 
Rudder.ProofChain.BlockSpecimenEventListener.start()
```

## ProofChain Contract Interactor

In order to run the interactor you need to fork ethereum node and run a script to add the operators using the docker:

1. Add `.env` file.

2. Inside `.env` add ERIGON_NODE variable and replace the node's url with yours:

```bash
export ERIGON_NODE="erigon.node.url"
```

3. Inside a terminal got to the rudder folder and run: 

```bash
docker compose --env-file ".env" -f "docker-compose-local.yml" up --remove-orphans
```

4. Inside a second terminal navigate to the `rudder` folder and run:

```elixir
iex -S mix 
```

then

```elixir
Rudder.ProofChain.Interactor.test_submit_block_result_proof(block_height)
```

or

```elixir
Rudder.ProofChain.Interactor.submit_block_result_proof(chain_id, block_height, block_specimen_hash, block_result_hash, url) 
```
