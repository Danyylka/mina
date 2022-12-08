open Core_kernel
open Mina_base
open Snark_params.Tick
open Currency

module Poly = struct
  [%%versioned
  module Stable = struct
    module V2 = struct
      type ( 'staged_ledger_hash
           , 'snarked_ledger_hash
           , 'local_state
           , 'time
           , 'body_reference
           , 'signed_amount
           , 'pending_coinbase_stack
           , 'fee_excess
           , 'sok_digest )
           t =
            ( 'staged_ledger_hash
            , 'snarked_ledger_hash
            , 'local_state
            , 'time
            , 'body_reference
            , 'signed_amount
            , 'pending_coinbase_stack
            , 'fee_excess
            , 'sok_digest )
            Mina_wire_types.Mina_state.Blockchain_state.Poly.V2.t =
        { staged_ledger_hash : 'staged_ledger_hash
        ; genesis_ledger_hash : 'snarked_ledger_hash
        ; ledger_proof_statement :
            ( 'snarked_ledger_hash
            , 'signed_amount
            , 'pending_coinbase_stack
            , 'fee_excess
            , 'sok_digest
            , 'local_state )
            Snarked_ledger_state.Poly.Stable.V2.t
        ; registers :
            ('snarked_ledger_hash, unit, 'local_state) Registers.Stable.V1.t
        ; timestamp : 'time
        ; body_reference : 'body_reference
        }
      [@@deriving sexp, fields, equal, compare, hash, yojson, hlist]
    end
  end]
end

[%%define_locally
Poly.
  ( staged_ledger_hash
  , genesis_ledger_hash
  , timestamp
  , body_reference
  , registers
  , ledger_proof_statement
  , to_hlist
  , of_hlist )]

let snarked_ledger_hash (t : _ Poly.t) = t.registers.second_pass_ledger

module Value = struct
  [%%versioned
  module Stable = struct
    module V2 = struct
      type t =
        ( Staged_ledger_hash.Stable.V1.t
        , Frozen_ledger_hash.Stable.V1.t
        , Local_state.Stable.V1.t
        , Block_time.Stable.V1.t
        , Consensus.Body_reference.Stable.V1.t
        , (Amount.Stable.V1.t, Sgn.Stable.V1.t) Signed_poly.Stable.V1.t
        , Pending_coinbase.Stack_versioned.Stable.V1.t
        , Fee_excess.Stable.V1.t
        , Sok_message.Digest.Stable.V1.t )
        Poly.Stable.V2.t
      [@@deriving sexp, equal, compare, hash, yojson]

      let to_latest = Fn.id
    end
  end]
end

type var =
  ( Staged_ledger_hash.var
  , Frozen_ledger_hash.var
  , Local_state.Checked.t
  , Block_time.Checked.t
  , Consensus.Body_reference.var
  , Currency.Amount.Signed.var
  , Pending_coinbase.Stack.var
  , Fee_excess.var
  , Sok_message.Digest.Checked.t )
  Poly.t

let create_value ~staged_ledger_hash ~genesis_ledger_hash ~registers ~timestamp
    ~body_reference ~ledger_proof_statement =
  { Poly.staged_ledger_hash
  ; timestamp
  ; genesis_ledger_hash
  ; registers
  ; body_reference
  ; ledger_proof_statement
  }

let typ : (var, Value.t) Typ.t =
  Typ.of_hlistable
    [ Staged_ledger_hash.typ
    ; Frozen_ledger_hash.typ
    ; Snarked_ledger_state.With_sok.typ
    ; Registers.typ
        [ Frozen_ledger_hash.typ
        ; Frozen_ledger_hash.typ
        ; Typ.unit
        ; Local_state.typ
        ]
    ; Block_time.Checked.typ
    ; Consensus.Body_reference.typ
    ]
    ~var_to_hlist:to_hlist ~var_of_hlist:of_hlist ~value_to_hlist:to_hlist
    ~value_of_hlist:of_hlist

module Impl = Pickles.Impls.Step

let var_to_input
    ({ staged_ledger_hash
     ; genesis_ledger_hash
     ; registers
     ; timestamp
     ; body_reference
     ; ledger_proof_statement
     } :
      var ) : Field.Var.t Random_oracle.Input.Chunked.t Checked.t =
  let open Random_oracle.Input.Chunked in
  let open Checked.Let_syntax in
  let registers =
    (* TODO: If this were the actual Registers itself (without the unit arg)
       then we could more efficiently deal with the transaction SNARK input
       (as we could reuse the hash)
    *)
    let { first_pass_ledger
        ; second_pass_ledger
        ; pending_coinbase_stack = ()
        ; local_state
        } =
      registers
    in
    Array.reduce_exn ~f:append
      [| Frozen_ledger_hash.var_to_input first_pass_ledger
       ; Frozen_ledger_hash.var_to_input second_pass_ledger
       ; Local_state.Checked.to_input local_state
      |]
  in
  let%map ledger_proof_statement =
    Snarked_ledger_state.With_sok.Checked.to_input ledger_proof_statement
  in
  List.reduce_exn ~f:append
    [ Staged_ledger_hash.var_to_input staged_ledger_hash
    ; Frozen_ledger_hash.var_to_input genesis_ledger_hash
    ; ledger_proof_statement
    ; registers
    ; Block_time.Checked.to_input timestamp
    ; Consensus.Body_reference.var_to_input body_reference
    ]

let to_input
    ({ staged_ledger_hash
     ; genesis_ledger_hash
     ; registers
     ; timestamp
     ; body_reference
     ; ledger_proof_statement
     } :
      Value.t ) =
  let open Random_oracle.Input.Chunked in
  let registers =
    (* TODO: If this were the actual Registers itself (without the unit arg)
       then we could more efficiently deal with the transaction SNARK input
       (as we could reuse the hash)
    *)
    let { first_pass_ledger
        ; second_pass_ledger
        ; pending_coinbase_stack = ()
        ; local_state
        } =
      registers
    in
    Array.reduce_exn ~f:append
      [| Frozen_ledger_hash.to_input first_pass_ledger
       ; Frozen_ledger_hash.to_input second_pass_ledger
       ; Local_state.to_input local_state
      |]
  in
  List.reduce_exn ~f:append
    [ Staged_ledger_hash.to_input staged_ledger_hash
    ; Frozen_ledger_hash.to_input genesis_ledger_hash
    ; Snarked_ledger_state.With_sok.to_input ledger_proof_statement
    ; registers
    ; Block_time.to_input timestamp
    ; Consensus.Body_reference.to_input body_reference
    ]

let set_timestamp t timestamp = { t with Poly.timestamp }

let negative_one
    ~(constraint_constants : Genesis_constants.Constraint_constants.t)
    ~(consensus_constants : Consensus.Constants.t) ~genesis_ledger_hash
    ~genesis_body_reference : Value.t =
  { staged_ledger_hash =
      Staged_ledger_hash.genesis ~constraint_constants ~genesis_ledger_hash
  ; genesis_ledger_hash
  ; ledger_proof_statement =
      Snarked_ledger_state.With_sok.genesis ~genesis_ledger_hash
  ; registers =
      { first_pass_ledger = genesis_ledger_hash
      ; second_pass_ledger = genesis_ledger_hash
      ; pending_coinbase_stack = ()
      ; local_state = Local_state.dummy ()
      }
  ; timestamp = consensus_constants.genesis_state_timestamp
  ; body_reference = genesis_body_reference
  }

(* negative_one and genesis blockchain states are equivalent *)
let genesis = negative_one

type display =
  ( string
  , string
  , Local_state.display
  , string
  , string
  , string
  , string
  , int
  , string )
  Poly.t
[@@deriving yojson]

let display
    ({ staged_ledger_hash
     ; genesis_ledger_hash
     ; ledger_proof_statement
     ; registers =
         { first_pass_ledger
         ; second_pass_ledger
         ; pending_coinbase_stack = ()
         ; local_state
         }
     ; timestamp
     ; body_reference
     } :
      Value.t ) : display =
  { Poly.staged_ledger_hash =
      Visualization.display_prefix_of_string @@ Ledger_hash.to_base58_check
      @@ Staged_ledger_hash.ledger_hash staged_ledger_hash
  ; genesis_ledger_hash =
      Visualization.display_prefix_of_string
      @@ Frozen_ledger_hash.to_base58_check @@ genesis_ledger_hash
  ; ledger_proof_statement =
      Snarked_ledger_state.With_sok.display ledger_proof_statement
  ; registers =
      { first_pass_ledger =
          Visualization.display_prefix_of_string
          @@ Frozen_ledger_hash.to_base58_check first_pass_ledger
      ; second_pass_ledger =
          Visualization.display_prefix_of_string
          @@ Frozen_ledger_hash.to_base58_check second_pass_ledger
      ; pending_coinbase_stack = ()
      ; local_state = Local_state.display local_state
      }
  ; timestamp =
      Time.to_string_trimmed ~zone:Time.Zone.utc
        (Block_time.to_time_exn timestamp)
  ; body_reference =
      Visualization.display_prefix_of_string
      @@ Consensus.Body_reference.to_hex body_reference
  }
