(** * More Logic *)

Require Export "Prop".

(* ############################################################ *)
(** * Existential Quantification *)

(** Another critical logical connective is _existential
    quantification_.  We can express it with the following
    definition: *)

Inductive ex (X:Type) (P : X->Prop) : Prop :=
  ex_intro : forall (witness:X), P witness -> ex X P.

(** That is, [ex] is a family of propositions indexed by a type [X]
    and a property [P] over [X].  In order to give evidence for the
    assertion "there exists an [x] for which the property [P] holds"
    we must actually name a _witness_ -- a specific value [x] -- and
    then give evidence for [P x], i.e., evidence that [x] has the
    property [P].

*)


(** *** *)
(** Coq's [Notation] facility can be used to introduce more
    familiar notation for writing existentially quantified
    propositions, exactly parallel to the built-in syntax for
    universally quantified propositions.  Instead of writing [ex nat
    ev] to express the proposition that there exists some number that
    is even, for example, we can write [exists x:nat, ev x].  (It is
    not necessary to understand exactly how the [Notation] definition
    works.) *)

Notation "'exists' x , p" := (ex _ (fun x => p))
  (at level 200, x ident, right associativity) : type_scope.
Notation "'exists' x : X , p" := (ex _ (fun x:X => p))
  (at level 200, x ident, right associativity) : type_scope.

(** *** *)
(** We can use the usual set of tactics for
    manipulating existentials.  For example, to prove an
    existential, we can [apply] the constructor [ex_intro].  Since the
    premise of [ex_intro] involves a variable ([witness]) that does
    not appear in its conclusion, we need to explicitly give its value
    when we use [apply]. *)

Example exists_example_1 : exists n, n + (n * n) = 6.
Proof.
  apply ex_intro with (witness:=2).
  reflexivity.  Qed.

(** Note that we have to explicitly give the witness. *)

(** *** *)
(** Or, instead of writing [apply ex_intro with (witness:=e)] all the
    time, we can use the convenient shorthand [exists e], which means
    the same thing. *)

Example exists_example_1' : exists n, n + (n * n) = 6.
Proof.
  exists 2.
  reflexivity.  Qed.

(** *** *)
(** Conversely, if we have an existential hypothesis in the
    context, we can eliminate it with [inversion].  Note the use
    of the [as...] pattern to name the variable that Coq
    introduces to name the witness value and get evidence that
    the hypothesis holds for the witness.  (If we don't
    explicitly choose one, Coq will just call it [witness], which
    makes proofs confusing.) *)

Theorem exists_example_2 : forall n,
  (exists m, n = 4 + m) ->
  (exists o, n = 2 + o).
Proof.
  intros n H.
  inversion H as [m Hm].
  exists (2 + m).
  apply Hm.  Qed.


(** Here is another example of how to work with existentials. *)
Lemma exists_example_3 :
  exists (n:nat), even n /\ beautiful n.
Proof.
(* WORKED IN CLASS *)
  exists 8.
  split.
  unfold even. simpl. reflexivity.
  apply b_sum with (n:=3) (m:=5).
  apply b_3. apply b_5.
Qed.

(** **** Exercise: 1 star, optional (english_exists) *)
(** In English, what does the proposition
      ex nat (fun n => beautiful (S n))
]]
    mean? *)

(* That there exists a natural number whose successor is beautiful. *)

(*
*)
(** **** Exercise: 1 star (dist_not_exists) *)
(** Prove that "[P] holds for all [x]" implies "there is no [x] for
    which [P] does not hold." *)

Theorem dist_not_exists : forall (X:Type) (P : X -> Prop),
  (forall x, P x) -> ~ (exists x, ~ P x).
Proof.
  intros. unfold not.
  intros. destruct H0.
  apply H0. auto.
Qed.

(** **** Exercise: 3 stars, optional (not_exists_dist) *)
(** (The other direction of this theorem requires the classical "law
    of the excluded middle".) *)

Theorem not_exists_dist :
  excluded_middle ->
  forall (X:Type) (P : X -> Prop),
    ~ (exists x, ~ P x) -> (forall x, P x).
Proof.
  intros.
  unfold excluded_middle in H.
  specialize (H (P x)).
  inversion H. assumption.
  contradiction H0.
  exists x. assumption.
Qed.

(** **** Exercise: 2 stars (dist_exists_or) *)
(** Prove that existential quantification distributes over
    disjunction. *)

Theorem dist_exists_or : forall (X:Type) (P Q : X -> Prop),
  (exists x, P x \/ Q x) <-> (exists x, P x) \/ (exists x, Q x).
Proof.
  intros. split; intros.
  inversion H. inversion H0.
  left. exists witness. assumption.
  right. exists witness. assumption.
  inversion H. inversion H0.
  exists witness. left. assumption.
  destruct H. destruct H.
  exists witness. left. assumption.
  destruct H0. exists witness.
  right. assumption.
Qed.


(* ###################################################### *)
(** * Evidence-carrying booleans. *)

(** So far we've seen two different forms of equality predicates:
[eq], which produces a [Prop], and
the type-specific forms, like [beq_nat], that produce [boolean]
values.  The former are more convenient to reason about, but
we've relied on the latter to let us use equality tests
in _computations_.  While it is straightforward to write lemmas
(e.g. [beq_nat_true] and [beq_nat_false]) that connect the two forms,
using these lemmas quickly gets tedious.
*)

(** *** *)
(**
It turns out that we can get the benefits of both forms at once
by using a construct called [sumbool]. *)

Inductive sumbool (A B : Prop) : Set :=
 | left : A -> sumbool A B
 | right : B -> sumbool A B.

Notation "{ A } + { B }" :=  (sumbool A B) : type_scope.

(** Think of [sumbool] as being like the [boolean] type, but instead
of its values being just [true] and [false], they carry _evidence_
of truth or falsity. This means that when we [destruct] them, we
are left with the relevant evidence as a hypothesis -- just as with [or].
(In fact, the definition of [sumbool] is almost the same as for [or].
The only difference is that values of [sumbool] are declared to be in
[Set] rather than in [Prop]; this is a technical distinction
that allows us to compute with them.) *)

(** *** *)

(** Here's how we can define a [sumbool] for equality on [nat]s *)

Theorem eq_nat_dec : forall n m : nat, {n = m} + {n <> m}.
Proof.
  (* WORKED IN CLASS *)
  intros n.
  induction n as [|n'].
  Case "n = 0".
    intros m.
    destruct m as [|m'].
    SCase "m = 0".
      left. reflexivity.
    SCase "m = S m'".
      right. intros contra. inversion contra.
  Case "n = S n'".
    intros m.
    destruct m as [|m'].
    SCase "m = 0".
      right. intros contra. inversion contra.
    SCase "m = S m'".
      destruct IHn' with (m := m') as [eq | neq].
      left. apply f_equal.  apply eq.
      right. intros Heq. inversion Heq as [Heq']. apply neq. apply Heq'.
Defined.

(** Read as a theorem, this says that equality on [nat]s is decidable:
that is, given two [nat] values, we can always produce either
evidence that they are equal or evidence that they are not.
Read computationally, [eq_nat_dec] takes two [nat] values and returns
a [sumbool] constructed with [left] if they are equal and [right]
if they are not; this result can be tested with a [match] or, better,
with an [if-then-else], just like a regular [boolean].
(Notice that we ended this proof with [Defined] rather than [Qed].
The only difference this makes is that the proof becomes _transparent_,
meaning that its definition is available when Coq tries to do reductions,
which is important for the computational interpretation.)
*)

(** *** *)
(**
Here's a simple example illustrating the advantages of the [sumbool] form. *)

Definition override' {X: Type} (f: nat->X) (k:nat) (x:X) : nat->X:=
  fun (k':nat) => if eq_nat_dec k k' then x else f k'.

Theorem override_same' : forall (X:Type) x1 k1 k2 (f : nat->X),
  f k1 = x1 ->
  (override' f k1 x1) k2 = f k2.
Proof.
  intros X x1 k1 k2 f. intros Hx1.
  unfold override'.
  destruct (eq_nat_dec k1 k2).   (* observe what appears as a hypothesis *)
  Case "k1 = k2".
    rewrite <- e.
    symmetry. apply Hx1.
  Case "k1 <> k2".
    reflexivity.  Qed.

(** Compare this to the more laborious proof (in MoreCoq.v) for the
   version of [override] defined using [beq_nat], where we had to
   use the auxiliary lemma [beq_nat_true] to convert a fact about booleans
   to a Prop. *)


(** **** Exercise: 1 star (override_shadow') *)
Theorem override_shadow' : forall (X:Type) x1 x2 k1 k2 (f : nat->X),
  (override' (override' f k1 x2) k1 x1) k2 = (override' f k1 x1) k2.
Proof.
  intros. unfold override'.
  destruct (eq_nat_dec k1 k2); auto.
Qed.


(* ####################################################### *)
(** * Additional Exercises *)

(** **** Exercise: 3 stars (all_forallb) *)
(** Inductively define a property [all] of lists, parameterized by a
    type [X] and a property [P : X -> Prop], such that [all X P l]
    asserts that [P] is true for every element of the list [l]. *)

Inductive all {X : Type} (P : X -> Prop) : list X -> Prop :=
  | vacuous : all P []
  | holds x xs : P x -> all P xs -> all P (x :: xs).

(** Recall the function [forallb], from the exercise
    [forall_exists_challenge] in chapter [Poly]: *)

Fixpoint forallb {X : Type} (test : X -> bool) (l : list X) : bool :=
  match l with
    | [] => true
    | x :: l' => andb (test x) (forallb test l')
  end.

(** Using the property [all], write down a specification for [forallb],
    and prove that it satisfies the specification. Try to make your
    specification as precise as possible.

    Are there any important properties of the function [forallb] which
    are not captured by your specification? *)

Theorem forallb_holds : forall X (test : X -> bool) (xs : list X),
  forallb test xs = true <-> all (fun x => test x = true) xs.
Proof.
  intros. split.
  - intros. induction xs. constructor.
    apply holds. simpl in H.
      destruct (test x). reflexivity. apply H.
    apply IHxs. simpl in H.
    apply andb_true_elim2 in H.
    assumption.
  - intros. induction H. auto.
    simpl. rewrite IHall.
    rewrite H. auto.
Qed.

(** **** Exercise: 4 stars, advanced (filter_challenge) *)
(** One of the main purposes of Coq is to prove that programs match
    their specifications.  To this end, let's prove that our
    definition of [filter] matches a specification.  Here is the
    specification, written out informally in English.

    Suppose we have a set [X], a function [test: X->bool], and a list
    [l] of type [list X].  Suppose further that [l] is an "in-order
    merge" of two lists, [l1] and [l2], such that every item in [l1]
    satisfies [test] and no item in [l2] satisfies test.  Then [filter
    test l = l1].

    A list [l] is an "in-order merge" of [l1] and [l2] if it contains
    all the same elements as [l1] and [l2], in the same order as [l1]
    and [l2], but possibly interleaved.  For example,
    [1,4,6,2,3]
    is an in-order merge of
    [1,6,2]
    and
    [4,3].
    Your job is to translate this specification into a Coq theorem and
    prove it.  (Hint: You'll need to begin by defining what it means
    for one list to be a merge of two others.  Do this with an
    inductive relation, not a [Fixpoint].)  *)

Inductive in_order_merge {X : Type} : list X -> list X -> list X -> Prop :=
  | in_order_l_nil : forall l, in_order_merge l nil l
  | in_order_r_nil : forall l, in_order_merge nil l l
  | in_order_l l1 l2 : forall a l,
      in_order_merge l1 l2 l -> in_order_merge (a :: l1) l2 (a :: l)
  | in_order_r l1 l2 : forall a l,
      in_order_merge l1 l2 l -> in_order_merge l1 (a :: l2) (a :: l).

Example in_order_merge_ex1 : in_order_merge [1;6;2] [4;3] [1;4;6;2;3].
Proof.
  apply in_order_l.
  apply in_order_r.
  apply in_order_l.
  apply in_order_l.
  apply in_order_r.
  apply in_order_l_nil.
Qed.

Lemma negb_flip : forall {X} (x : X) (test : X -> bool),
  negb (test x) = true -> test x = false.
Proof.
  intros. destruct (test x). inversion H. reflexivity.
Qed.

(* Given statements of truth in the context, and a goal which can be
   determined solely from those statements, discharge the goal. *)
Ltac elim_truth :=
  simpl in *; repeat (match goal with
  | [ H: andb (negb ?X) _ = true |- context [if ?X then _ else _] ] =>
    assert (X = false) as Hfalse by solve [
      apply andb_true_elim1 in H;
      apply negb_flip in H; assumption
    ]; rewrite Hfalse; clear Hfalse
  | [ H: andb ?X _ = true |- context [if ?X then _ else _] ] =>
    assert (X = true) as Htrue by solve [
      apply andb_true_elim1 in H; assumption
    ]; rewrite Htrue; clear Htrue
  | [ H: andb _ ?X = true |- context [?X = true] ] =>
      apply andb_true_elim2 in H; assumption
  end).

Theorem filter_challenge : forall {X} (test : X -> bool) (l l1 l2 : list X),
  in_order_merge l1 l2 l
    -> forallb test l1 = true
    -> forallb (fun x => negb (test x)) l2 = true -> filter test l = l1.
Proof.
  Ltac logic_puzzle hyp :=
    simpl in *; elim_truth;
    try (try f_equal; apply hyp; elim_truth; auto).

  intros. induction H; subst; simpl.
  - induction l. auto. logic_puzzle IHl.
  - induction l. auto. logic_puzzle IHl.
  - logic_puzzle IHin_order_merge.
  - logic_puzzle IHin_order_merge.
Qed.

(** **** Exercise: 5 stars, advanced, optional (filter_challenge_2) *)
(** A different way to formally characterize the behavior of [filter]
    goes like this: Among all subsequences of [l] with the property
    that [test] evaluates to [true] on all their members, [filter test
    l] is the longest.  Express this claim formally and prove it. *)

Inductive is_subseq {X} : list X -> list X -> Prop :=
  | subseq_nil : forall l, is_subseq nil l
  | subseq_cons : forall x m l, is_subseq m l -> is_subseq (x :: m) (x :: l)
  | subseq_skip : forall x m l, is_subseq m l -> is_subseq m (x :: l).

Example is_subseq_ex1 : is_subseq [1;2;3] [1;5;2;4;6;3].
Proof. repeat constructor. Qed.

(* Example is_subseq_ex2 : is_subseq [1;2;3] [1;5;2;4;6]. *)
(* Proof. repeat constructor. Abort. *)

(* Example is_subseq_ex3 : is_subseq [1;3;2] [1;5;2;4;6;3]. *)
(* Proof. repeat constructor. Abort. *)

Lemma self_subseq : forall {X} (l : list X), is_subseq l l.
Proof.
  intros.
  induction l; constructor.
  apply IHl.
Qed.

Lemma subseq_of_nil : forall {X} (l : list X), is_subseq l [] -> l = [].
Proof.
  intros.
  inversion H. auto.
Qed.

Lemma is_subseq_uncons : forall {X} (x : X) (l m : list X),
  is_subseq (x :: m) l -> is_subseq m l.
Proof.
  intros.
  induction l.
    inversion H.
  constructor.
  inversion H; subst.
    assumption.
  apply IHl.
  assumption.
Qed.

Lemma le_succ : forall (x y : nat), x <= y -> x <= S y.
Proof. auto. Qed.

Lemma filter_challenge_2 : forall {X} (test : X -> bool) (l m : list X),
  is_subseq m l -> forallb test m = true -> length m <= length (filter test l).
Proof.
  intros X test l.
  induction l as [| x xs]; intros; simpl;
  inversion H; subst; simpl;
  try (apply Le.le_0_n).
  - elim_truth.
    apply Le.le_n_S.
    apply IHxs. assumption.
    elim_truth.
  - destruct (test x);
    try (apply le_succ);
    apply IHxs; assumption.
Qed.

(** **** Exercise: 4 stars, advanced (no_repeats) *)
(** The following inductively defined proposition... *)

Inductive appears_in {X:Type} (a:X) : list X -> Prop :=
  | ai_here : forall l, appears_in a (a::l)
  | ai_later : forall b l, appears_in a l -> appears_in a (b::l).

(** ...gives us a precise way of saying that a value [a] appears at
    least once as a member of a list [l].

    Here's a pair of warm-ups about [appears_in].
*)

(* Lemma appears_in_cons : forall (X:Type) (xs ys : list X) (x:X), *)
(*   appears_in x (x :: xs) -> appears_in x xs \/ appears_in x ys. *)
(* Proof. *)

Lemma appears_in_app : forall (X:Type) (xs ys : list X) (x:X),
  appears_in x (xs ++ ys) -> appears_in x xs \/ appears_in x ys.
Proof with auto.
  intros.
  generalize dependent ys.
  induction xs.
    right. simpl in H...
  intros. inversion H. subst.
  - destruct ys eqn:Heqe.
      rewrite app_nil in H...
      left. constructor.
    constructor. constructor.
  - destruct ys eqn:Heqe.
      left. rewrite app_nil in H...
    specialize (IHxs (x1 :: l0)).
    apply IHxs in H1. inversion H1.
    constructor. constructor...
    right...
Qed.

Theorem appears_cons : forall (X : Type) x y (xs : list X),
  appears_in x (y :: xs) -> x = y \/ appears_in x xs.
Proof.
  intros.
  inversion H; subst.
    left. reflexivity.
  right. assumption.
Qed.

Theorem appears_before_cons : forall (X : Type) x y (xs : list X),
  appears_in x (y :: xs) -> x <> y -> appears_in x xs.
Proof.
  intros.
  rewrite app_cons in H.
  apply appears_in_app in H.
  intuition.
  inversion H1; subst.
    contradiction H0.
    reflexivity.
  inversion H2.
Qed.

Theorem appears_cons_flip : forall (X : Type) x y z (xs : list X),
   appears_in x (y :: z :: xs) -> appears_in x (z :: y :: xs).
Proof.
  intros.
  inversion H; subst.
    constructor.
    constructor.
  inversion H1; subst.
    constructor.
  constructor.
  constructor.
  assumption.
Qed.

Lemma app_appears_in : forall (X:Type) (xs ys : list X) (x:X),
  appears_in x xs \/ appears_in x ys -> appears_in x (xs ++ ys).
Proof.
  intros.
  destruct H.
    induction xs.
      inversion H.
    inversion H; simpl; subst.
      constructor.
      constructor. auto.
  induction xs; simpl.
    assumption.
  constructor. auto.
Qed.

(** Now use [appears_in] to define a proposition [disjoint X l1 l2],
    which should be provable exactly when [l1] and [l2] are
    lists (with elements of type X) that have no elements in common. *)

Definition disjoint {X : Type} (l1 l2 : list X) : Prop :=
  forall x, appears_in x l1 -> not (appears_in x l2).

Example ex_disjoint_1 : disjoint [1; 2; 3] [4; 5; 6].
Proof.
  unfold disjoint.
  intros.
  unfold not.
  intros.
  inversion H; subst.
    inversion H0; subst.
    inversion H2; subst.
    inversion H3; subst.
    inversion H4.
  inversion H2; subst.
    inversion H0; subst.
    inversion H3; subst.
    inversion H4; subst.
    inversion H5.
  inversion H3; subst.
    inversion H0; subst.
    inversion H4; subst.
    inversion H5; subst.
    inversion H6.
  inversion H4.
Qed.

Example ex_disjoint_2 : disjoint [1; 2; 3] [3; 4; 5].
Proof.
  unfold disjoint.
  intros.
  unfold not.
  intros.
  inversion H; subst.
    inversion H0; subst.
    inversion H2; subst.
    inversion H3; subst.
    inversion H4.
  inversion H2; subst.
    inversion H0; subst.
    inversion H3; subst.
    inversion H4; subst.
    inversion H5.
  inversion H3; subst.
    inversion H0; subst.
Abort.

(** Next, use [appears_in] to define an inductive proposition
    [no_repeats X l], which should be provable exactly when [l] is a
    list (with elements of type [X]) where every member is different
    from every other.  For example, [no_repeats nat [1,2,3,4]] and
    [no_repeats bool []] should be provable, while [no_repeats nat
    [1,2,1]] and [no_repeats bool [true,true]] should not be.  *)

Inductive no_repeats {X : Type} : list X -> Prop :=
  | no_repeats_nil : no_repeats []
  | no_repeats_cons x l : no_repeats l -> not (appears_in x l) -> no_repeats (x :: l).

Example no_repeats_nat1 : no_repeats [1; 2; 3; 4].
Proof.
  constructor.
  constructor.
  constructor.
  constructor.
  constructor.
  unfold not. intros. inversion H.
  unfold not. intros. inversion H; subst. inversion H1.
  unfold not. intros. inversion H; subst. inversion H1; subst.
    inversion H2.
  unfold not. intros. inversion H; subst. inversion H1; subst.
    inversion H2; subst. inversion H3.
Qed.

Example no_repeats_bool1 : @no_repeats bool [].
Proof.
  constructor.
Qed.

Example no_repeats_nat2 : no_repeats [1; 2; 1].
Proof.
  constructor.
  constructor.
  constructor.
  constructor.
  unfold not. intros. inversion H.
  unfold not. intros. inversion H; subst. inversion H1.
  unfold not. intros. inversion H; subst. inversion H1; subst.
Abort.

Example no_repeats_bool2 : no_repeats [true; true].
Proof.
  constructor.
  constructor.
  constructor.
  unfold not. intros. inversion H.
  unfold not. intros. inversion H; subst.
Abort.

Theorem no_repeats_uncons : forall (X : Type) x (l : list X),
  no_repeats (x :: l) -> no_repeats l.
Proof.
  intros.
  induction l.
    constructor.
  inversion H; subst.
  assumption.
Qed.

(** Finally, state and prove one or more interesting theorems relating
    [disjoint], [no_repeats] and [++] (list append).  *)

Lemma disjoint_nil : forall {X} (l : list X), disjoint [] l.
Proof.
  intros. induction l; unfold disjoint, not; intros; inversion H.
Qed.

Lemma disjoint_cons : forall {X} (x : X) (l1 l2 : list X),
  disjoint l1 l2 -> not (appears_in x l2) -> disjoint (x :: l1) l2.
Proof.
  intros X x l1.
  induction l1; intros; simpl;
  unfold disjoint in *; intros;
  unfold not in *; intros;
  inversion H1; subst.
  - contradiction H0.
  - inversion H2; subst; inversion H4.
  - contradiction H2.
  - destruct l2. inversion H2.
    contradiction (H x1).
Qed.

Lemma not_appears_in_app : forall {X} (x : X) (l1 l2 : list X),
  not (appears_in x (l1 ++ l2)) -> not (appears_in x l2).
Proof.
  intros. unfold not in *. intros.
  apply H.
  apply app_appears_in.
  right. assumption.
Qed.

Lemma not_appears_in_cons : forall {X} (x y : X) (l2 : list X),
  not (appears_in x (y :: l2)) -> not (appears_in x l2).
Proof.
  intros. unfold not in *. intros.
  apply H.
  constructor.
  assumption.
Qed.

Theorem no_repeats_and_disjoint : forall {X} (l1 l2 : list X),
  no_repeats (l1 ++ l2) -> disjoint l1 l2.
Proof.
  intros X l1.
  induction l1 as [| x xs]; intros; simpl.
    apply disjoint_nil.
  inversion H; subst.
  apply disjoint_cons.
    apply IHxs. assumption.
  apply not_appears_in_app in H3.
  assumption.
Qed.

(** **** Exercise: 3 stars (nostutter) *)
(** Formulating inductive definitions of predicates is an important
    skill you'll need in this course.  Try to solve this exercise
    without any help at all (except from your study group partner, if
    you have one).

    We say that a list of numbers "stutters" if it repeats the same
    number consecutively.  The predicate "[nostutter mylist]" means
    that [mylist] does not stutter.  Formulate an inductive definition
    for [nostutter].  (This is different from the [no_repeats]
    predicate in the exercise above; the sequence [1,4,1] repeats but
    does not stutter.) *)

Inductive nostutter:  list nat -> Prop :=
  | nostutter_nil    : nostutter nil
  | nostutter_sing x : nostutter [x]
  | nostutter_cons x y xs :
      nostutter (y :: xs) -> x <> y -> nostutter (x :: y :: xs).

(** Make sure each of these tests succeeds, but you are free
    to change the proof if the given one doesn't work for you.
    Your definition might be different from mine and still correct,
    in which case the examples might need a different proof.

    The suggested proofs for the examples (in comments) use a number
    of tactics we haven't talked about, to try to make them robust
    with respect to different possible ways of defining [nostutter].
    You should be able to just uncomment and use them as-is, but if
    you prefer you can also prove each example with more basic
    tactics.  *)

Example test_nostutter_1:  nostutter [3;1;4;1;5;6].
Proof. repeat constructor; apply beq_nat_false; auto. Qed.

Example test_nostutter_2:  nostutter [].
Proof. repeat constructor; apply beq_nat_false; auto. Qed.

Example test_nostutter_3:  nostutter [5].
Proof. repeat constructor; apply beq_nat_false; auto. Qed.

Example test_nostutter_4:      not (nostutter [3;1;1;4]).
Proof. intro.
  repeat match goal with
    h: nostutter _ |- _ => inversion h; clear h; subst
  end.
  contradiction H5; auto.
Qed.

(** **** Exercise: 4 stars, advanced (pigeonhole principle) *)
(** The "pigeonhole principle" states a basic fact about counting:
   if you distribute more than [n] items into [n] pigeonholes, some
   pigeonhole must contain at least two items.  As is often the case,
   this apparently trivial fact about numbers requires non-trivial
   machinery to prove, but we now have enough... *)

(** First a pair of useful lemmas (we already proved these for lists
    of naturals, but not for arbitrary lists). *)

Lemma app_length : forall (X:Type) (l1 l2 : list X),
  length (l1 ++ l2) = length l1 + length l2.
Proof.
  intros X l1.
  induction l1; intros; simpl; auto.
Qed.

Lemma appears_in_app_split : forall (X:Type) (x:X) (l:list X),
  appears_in x l -> exists l1, exists l2, l = l1 ++ (x::l2).
Proof.
  intros.
  induction H.
    exists nil.
    exists l. reflexivity.
  destruct IHappears_in.
  destruct H0.
  rewrite H0.
  exists (b :: witness).
  exists witness0.
  reflexivity.
Qed.

(** Now define a predicate [repeats] (analogous to [no_repeats] in the
   exercise above), such that [repeats X l] asserts that [l] contains
   at least one repeated element (of type [X]).  *)

Inductive repeats {X:Type} : list X -> Prop :=
  | repeats_head x xs : appears_in x xs -> repeats (x :: xs)
  | repeats_tail x xs : repeats xs -> repeats (x :: xs).

(** Now here's a way to formalize the pigeonhole principle. List [l2]
    represents a list of pigeonhole labels, and list [l1] represents
    the labels assigned to a list of items: if there are more items
    than labels, at least two items must have the same label.  This
    proof is much easier if you use the [excluded_middle] hypothesis
    to show that [appears_in] is decidable, i.e. [forall x
    l, (appears_in x l) \/ ~ (appears_in x l)].  However, it is also
    possible to make the proof go through _without_ assuming that
    [appears_in] is decidable; if you can manage to do this, you will
    not need the [excluded_middle] hypothesis. *)

Lemma flip_neq : forall (X : Type) (x y : X), x <> y -> y <> x.
Proof.
  intros. unfold not in *. intros.
  apply H. symmetry. auto.
Qed.

Theorem pigeonhole_principle : forall X (l1 l2 : list X),
  excluded_middle
    -> (forall x, appears_in x l1 -> appears_in x l2)
    -> length l2 < length l1
    -> repeats l1.
Proof.
  induction l1 as [|x xs IHxs]; intros l2 LEM Happ Hlen.
    inversion Hlen.
  assert (appears_in x xs \/ ~ appears_in x xs). apply LEM.
  inversion H. left. assumption. right.
  pose (ai_here x xs).
  apply Happ in a.
  apply appears_in_app_split in a.
  destruct a. destruct H1.
  apply (IHxs (witness ++ witness0)); subst. auto. intros.
    assert (x = x0 \/ x <> x0). apply LEM.
    inversion H2; subst. contradiction H0.
    apply app_appears_in.
    specialize (Happ x0).
    apply ai_later with (b := x) in H1.
    apply Happ in H1.
    apply appears_in_app in H1.
    inversion H1. left. assumption. right.
    apply appears_before_cons with (y := x). assumption.
    apply flip_neq. apply H3.
  rewrite app_length in Hlen. simpl in Hlen.
  apply Le.le_S_n in Hlen.
  rewrite app_length.
  unfold lt in *.
  rewrite plus_n_Sm. auto.
Qed.

(* $Date: 2014-02-22 09:43:41 -0500 (Sat, 22 Feb 2014) $ *)
