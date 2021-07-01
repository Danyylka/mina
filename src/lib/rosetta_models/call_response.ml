(*
 * This file has been generated by the OCamlClientCodegen generator for openapi-generator.
 *
 * Generated by: https://openapi-generator.tech
 *
 * Schema Call_response.t : CallResponse contains the result of a `/call` invocation.
 *)

type t =
  { (* Result contains the result of the `/call` invocation. This result will not be inspected or interpreted by Rosetta tooling and is left to the caller to decode. *)
    _result : Yojson.Safe.t
  ; (* Idempotent indicates that if `/call` is invoked with the same CallRequest again, at any point in time, it will return the same CallResponse. Integrators may cache the CallResponse if this is set to true to avoid making unnecessary calls to the Rosetta implementation. For this reason, implementers should be very conservative about returning true here or they could cause issues for the caller. *)
    idempotent : bool
  }
[@@deriving yojson { strict = false }, show]

(** CallResponse contains the result of a `/call` invocation. *)
let create (_result : Yojson.Safe.t) (idempotent : bool) : t =
  { _result; idempotent }
