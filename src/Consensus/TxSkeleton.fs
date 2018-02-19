﻿module Consensus.TxSkeleton

open Consensus
open Consensus
open Consensus.Types

type Input =
    | PointedOutput of PointedOutput
    | Mint of Spend

type T = {
    pInputs: Input list
    outputs: Output list
}

let empty =
    {
        pInputs = []
        outputs = []
    }

let addInputs inputs (txSkeleton:T) =
    {txSkeleton with pInputs=List.append txSkeleton.pInputs inputs}

let addOutput output (txSkeleton:T) =
    {txSkeleton with outputs=List.append txSkeleton.outputs [output]}

let addChange asset inputsAmount outputsAmount pkHash txSkeleton =
    if inputsAmount > outputsAmount then
        addOutput {lock=PK pkHash;spend={amount=inputsAmount-outputsAmount;asset=asset}} txSkeleton
    else
        txSkeleton

let checkPrefix txSub txSuper =
    let (=>) (super:List<'a>) (sub:List<'a>) =
        let subLen, superLen = List.length sub, List.length super
        superLen >= subLen && super.[0..subLen-1] = sub

    if txSuper.pInputs => txSub.pInputs &&
       txSuper.outputs => txSub.outputs then
        Ok txSuper
    else
        Error "invalid prefix"

let fromTransaction tx (outputs : Output List)=
    match List.fold (fun state input ->
        state
        |> Option.bind (
            fun (inputs, outputs) ->
                match input with
                | Types.Input.Outpoint outpoint ->
                    List.tryHead outputs
                    |> Option.bind (fun output ->
                        Some (PointedOutput (outpoint, output) :: inputs, List.tail outputs)
                    )
                | Types.Input.Mint spend ->
                    Some (Mint spend :: inputs, outputs)
        )) (Some ([], outputs)) tx.inputs with
    | Some (inputs, _) ->
        Ok {
            pInputs = List.rev inputs
            outputs = tx.outputs
        }
    | None ->
        Error "could not construct txSkeleton"

let applyMask tx cw =
    let (=>) list length =
        List.length list |> uint32 >= length

    if tx.pInputs => cw.inputsLength &&
       tx.outputs => cw.outputsLength then
        Ok {
            tx with
                pInputs = tx.pInputs.[0 .. int cw.beginInputs - 1 ]
                outputs = tx.outputs.[0 .. int cw.beginOutputs - 1 ]
        }
    else
        Error "could not apply mask"

let isSkeletonOf txSkeleton tx outputs =
    let inputsOfSkeleton =
        txSkeleton.pInputs
        |> List.map (function
            | Mint spend ->
                Types.Input.Mint spend
            | PointedOutput (outpoint, _) ->
                Types.Input.Outpoint outpoint)

    let outputsFromSkeleton =
        txSkeleton.pInputs
        |> List.choose (function
            | Mint _ ->
                None
            | PointedOutput (_, output) ->
                Some output)

    tx.inputs = inputsOfSkeleton // Check that the contract didn't change the inputs
    && outputs = outputsFromSkeleton
    && tx.outputs = txSkeleton.outputs

let getContractWitness cHash command data returnAddress initialTxSkelton finalTxSkeleton =
    let length list = List.length list |> uint32

    let returnAddressIndex =
        List.tryFindIndex (fun output -> output.lock = returnAddress) finalTxSkeleton.outputs
        |> Option.map uint32

    ContractWitness {
        cHash = cHash
        command = command
        data = data
        returnAddressIndex = returnAddressIndex
        beginInputs = length initialTxSkelton.pInputs
        beginOutputs = length initialTxSkelton.outputs
        inputsLength = length finalTxSkeleton.pInputs - length initialTxSkelton.pInputs
        outputsLength = length finalTxSkeleton.outputs - length initialTxSkelton.outputs
    }
