# Changelog for the [`clash-ghc`](http://hackage.haskell.org/package/clash-ghc) package

## 1.0.1
* Fixes issues:
  * [#810](https://github.com/clash-lang/clash-compiler/issues/810): Verilog backend now correctly specifies type of `BitVector 1`
  * [#811](https://github.com/clash-lang/clash-compiler/issues/811): Improve module load behavior in clashi
  * [#439](https://github.com/clash-lang/clash-compiler/issues/439): Template Haskell splices and TopEntity annotations can now be used in clashi
  * [#818](https://github.com/clash-lang/clash-compiler/issues/818): Fixed various mistakes in tutorial
  * [#662](https://github.com/clash-lang/clash-compiler/issues/662): Clash will now constant specialize partially constant constructs
  * [#700](https://github.com/clash-lang/clash-compiler/issues/700): Check work content of expression in cast before warning users. Should eliminate a lot of (superfluous) warnings about "specializing on non work-free cast"s.
  * [#837](https://github.com/clash-lang/clash-compiler/issues/837): Blackboxes will now report clearer error messages if they're given unexpected arguments.
  * [#869](https://github.com/clash-lang/clash-compiler/issues/869): PLL is duplicated in Blinker.hs example

* Small fixes without issue reports:
  * Fix bug in `rnfX` defined for `Down` ([814fd52](https://github.com/clash-lang/clash-compiler/commit/814fd520191123be38af8ef28fc49130424f3b93))
  * Report blackbox name when encountering an error in 'setSym' ([#858](https://github.com/clash-lang/clash-compiler/pull/858))
  * Fix blackbox issues causing Clash to generate invalid HDL ([#865](https://github.com/clash-lang/clash-compiler/pull/865))
  * Adds '--enable-shared-executables' for nix builds; this should make Clash run _much_ faster ([#894](https://github.com/clash-lang/clash-compiler/pull/894))

## 1.0.0 *September 3rd 2019*
* 10x - 50x faster compile times
* New features:
  * API changes: check the migration guide at the end of `Clash.Tutorial`
  * All memory elements now have an (implicit) enable line; "Gated" clocks have
    been removed as the clock wasn't actually gated, but implemented as an
    enable line.
  * Circuit domains are now configurable in:
    * (old) The clock period
    * (new) Clock edge on which memory elements latch their inputs
      (rising edge or falling edge)
    * (new) Whether the reset port of a memory element is level sensitive
      (asynchronous reset) or edge sensitive (synchronous reset)
    * (new) Whether the reset port of a memory element is active-high or
      active-low (negated reset)
    * (new) Whether memory element power on in a configurable/defined state
      (common on FPGAs) or in an undefined state (ASICs)

    * See the [blog post](https://clash-lang.org/blog/0005-synthesis-domain/) on this new feature
  * Data types can now be given custom bit-representations: http://hackage.haskell.org/package/clash-prelude/docs/Clash-Annotations-BitRepresentation.html
  * Annotate expressions with attributes that persist in the generated HDL,
    e.g. synthesis directives: http://hackage.haskell.org/package/clash-prelude/docs/Clash-Annotations-SynthesisAttributes.html
  * Control (System)Verilog module instance, and VHDL entity instantiation names
    in generated code: http://hackage.haskell.org/package/clash-prelude/docs/Clash-Magic.html
  * Much improved infrastructure for handling of unknown values: defined spine,
    but unknown leafs: http://hackage.haskell.org/package/clash-prelude/docs/Clash-XException.html#t:NFDataX
  * Experimental: Multiple hidden clocks. Can be enabled by compiling
    `clash-prelude` with `-fmultiple-hidden`
  * Experimental: Limited GADT support (pattern matching on vectors, or custom
    GADTs as longs as their usage can be statically removed; no support of
    recursive GADTs)
  * Experimental: Use regular Haskell functions to generate HDL black boxes for
    primitives (in an addition to existing string templates for HDL black boxes)
    See for example: http://hackage.haskell.org/package/clash-lib/docs/Clash-Primitives-Intel-ClockGen.html

* Fixes issues:
  * [#316](https://github.com/clash-lang/clash-prelude/issues/316)
  * [#319](https://github.com/clash-lang/clash-prelude/issues/319)
  * [#323](https://github.com/clash-lang/clash-prelude/issues/323)
  * [#324](https://github.com/clash-lang/clash-prelude/issues/324)
  * [#329](https://github.com/clash-lang/clash-prelude/issues/329)
  * [#331](https://github.com/clash-lang/clash-prelude/issues/331)
  * [#332](https://github.com/clash-lang/clash-prelude/issues/332)
  * [#335](https://github.com/clash-lang/clash-prelude/issues/335)
  * [#348](https://github.com/clash-lang/clash-prelude/issues/348)
  * [#349](https://github.com/clash-lang/clash-prelude/issues/349)
  * [#350](https://github.com/clash-lang/clash-prelude/issues/350)
  * [#351](https://github.com/clash-lang/clash-prelude/issues/351)
  * [#352](https://github.com/clash-lang/clash-prelude/issues/352)
  * [#353](https://github.com/clash-lang/clash-prelude/issues/353)
  * [#358](https://github.com/clash-lang/clash-prelude/issues/358)
  * [#359](https://github.com/clash-lang/clash-prelude/issues/359)
  * [#363](https://github.com/clash-lang/clash-prelude/issues/363)
  * [#364](https://github.com/clash-lang/clash-prelude/issues/364)
  * [#365](https://github.com/clash-lang/clash-prelude/issues/365)
  * [#371](https://github.com/clash-lang/clash-prelude/issues/371)
  * [#372](https://github.com/clash-lang/clash-prelude/issues/372)
  * [#373](https://github.com/clash-lang/clash-prelude/issues/373)
  * [#378](https://github.com/clash-lang/clash-prelude/issues/378)
  * [#380](https://github.com/clash-lang/clash-prelude/issues/380)
  * [#381](https://github.com/clash-lang/clash-prelude/issues/381)
  * [#382](https://github.com/clash-lang/clash-prelude/issues/382)
  * [#383](https://github.com/clash-lang/clash-prelude/issues/383)
  * [#387](https://github.com/clash-lang/clash-prelude/issues/387)
  * [#393](https://github.com/clash-lang/clash-prelude/issues/393)
  * [#396](https://github.com/clash-lang/clash-prelude/issues/396)
  * [#398](https://github.com/clash-lang/clash-prelude/issues/398)
  * [#399](https://github.com/clash-lang/clash-prelude/issues/399)
  * [#401](https://github.com/clash-lang/clash-prelude/issues/401)
  * [#403](https://github.com/clash-lang/clash-prelude/issues/403)
  * [#407](https://github.com/clash-lang/clash-prelude/issues/407)
  * [#412](https://github.com/clash-lang/clash-prelude/issues/412)
  * [#413](https://github.com/clash-lang/clash-prelude/issues/413)
  * [#420](https://github.com/clash-lang/clash-prelude/issues/420)
  * [#422](https://github.com/clash-lang/clash-prelude/issues/422)
  * [#423](https://github.com/clash-lang/clash-prelude/issues/423)
  * [#424](https://github.com/clash-lang/clash-prelude/issues/424)
  * [#438](https://github.com/clash-lang/clash-prelude/issues/438)
  * [#450](https://github.com/clash-lang/clash-prelude/issues/450)
  * [#452](https://github.com/clash-lang/clash-prelude/issues/452)
  * [#455](https://github.com/clash-lang/clash-prelude/issues/455)
  * [#460](https://github.com/clash-lang/clash-prelude/issues/460)
  * [#461](https://github.com/clash-lang/clash-prelude/issues/461)
  * [#463](https://github.com/clash-lang/clash-prelude/issues/463)
  * [#468](https://github.com/clash-lang/clash-prelude/issues/468)
  * [#475](https://github.com/clash-lang/clash-prelude/issues/475)
  * [#476](https://github.com/clash-lang/clash-prelude/issues/476)
  * [#500](https://github.com/clash-lang/clash-prelude/issues/500)
  * [#507](https://github.com/clash-lang/clash-prelude/issues/507)
  * [#512](https://github.com/clash-lang/clash-prelude/issues/512)
  * [#516](https://github.com/clash-lang/clash-prelude/issues/516)
  * [#517](https://github.com/clash-lang/clash-prelude/issues/517)
  * [#526](https://github.com/clash-lang/clash-prelude/issues/526)
  * [#556](https://github.com/clash-lang/clash-prelude/issues/556)
  * [#560](https://github.com/clash-lang/clash-prelude/issues/560)
  * [#566](https://github.com/clash-lang/clash-prelude/issues/566)
  * [#567](https://github.com/clash-lang/clash-prelude/issues/567)
  * [#569](https://github.com/clash-lang/clash-prelude/issues/569)
  * [#573](https://github.com/clash-lang/clash-prelude/issues/573)
  * [#575](https://github.com/clash-lang/clash-prelude/issues/575)
  * [#581](https://github.com/clash-lang/clash-prelude/issues/581)
  * [#582](https://github.com/clash-lang/clash-prelude/issues/582)
  * [#586](https://github.com/clash-lang/clash-prelude/issues/586)
  * [#588](https://github.com/clash-lang/clash-prelude/issues/588)
  * [#591](https://github.com/clash-lang/clash-prelude/issues/591)
  * [#596](https://github.com/clash-lang/clash-prelude/issues/596)
  * [#601](https://github.com/clash-lang/clash-prelude/issues/601)
  * [#607](https://github.com/clash-lang/clash-prelude/issues/607)
  * [#629](https://github.com/clash-lang/clash-prelude/issues/629)
  * [#637](https://github.com/clash-lang/clash-prelude/issues/637)
  * [#644](https://github.com/clash-lang/clash-prelude/issues/644)
  * [#647](https://github.com/clash-lang/clash-prelude/issues/647)
  * [#661](https://github.com/clash-lang/clash-prelude/issues/661)
  * [#668](https://github.com/clash-lang/clash-prelude/issues/668)
  * [#677](https://github.com/clash-lang/clash-prelude/issues/677)
  * [#678](https://github.com/clash-lang/clash-prelude/issues/678)
  * [#682](https://github.com/clash-lang/clash-prelude/issues/682)
  * [#691](https://github.com/clash-lang/clash-prelude/issues/691)
  * [#703](https://github.com/clash-lang/clash-prelude/issues/703)
  * [#713](https://github.com/clash-lang/clash-prelude/issues/713)
  * [#715](https://github.com/clash-lang/clash-prelude/issues/715)
  * [#727](https://github.com/clash-lang/clash-prelude/issues/727)
  * [#730](https://github.com/clash-lang/clash-prelude/issues/730)
  * [#736](https://github.com/clash-lang/clash-prelude/issues/736)
  * [#738](https://github.com/clash-lang/clash-prelude/issues/738)

## 0.99.3 *July 28th 2018*
* Fixes bugs:
  * Evaluator recognizes `Bit` literals [#329](https://github.com/clash-lang/clash-compiler/issues/329)
  * Use existential type-variables in context of GADT pattern match
  * Do not create zero-bit temporary variables in generated HDL
  * Use correct arguments in nested primitives [#323](https://github.com/clash-lang/clash-compiler/issues/329)
  * Zero-constructor data type needs 0 bits [#238](https://github.com/clash-lang/clash-compiler/issues/238)
  * Create empty component when result needs 0 bits
  * Evaluator performs BigNat arithmetic

## 0.99.1 *May 12th 2018*
* Allow `~NAME[N]` tag inside `~GENSYM[X]`
* Support HDL record selector generation [#313](https://github.com/clash-lang/clash-compiler/pull/313)
* `InlinePrimitive` support: specify HDL primitives inline with Haskell code

## 0.99 *March 31st 2018*
* New features:
  * Support for `clash-prelude-0.99`:
      * Explicit clock and reset arguments
      * Overhaul of `TopEntity` annotations
  * Hierarchies with multiple synthesisable boundaries by allowing more than one
    function in scope to have a `Synthesize` annotation.
    * Local caching of functions with a `Synthesize` annotation
  * `Bit` type is mapped to a HDL scalar type (e.g. `std_logic` in VHDL)
  * Improved name preservation
  * Zero-bit values are filtered out of the generated HDL
  * Improved compile-time computation
* Many bug fixes

## 0.7.2
* New features:
  * Sum-of-product types: unused bits now "don't-care" [#212](https://github.com/clash-lang/clash-compiler/commit/fabf745793491ce3baf84ef0066b4ccf0753d503)
* Fixes bugs:
  * Eagerness bug in `regEn` [#104](https://github.com/clash-lang/clash-prelude/issues/104) (Thanks to @cbiffle)

## 0.7.1 *April 11th 2017*
* New features:
  * Support distribution of primitive templates with Cabal/Hackage packages [commit](https://github.com/clash-lang/clash-compiler/commit/82cd31863aafcbaf3bdbf7746d89d13859af5aaf)
  * Find memory data files and primitive files relative to import dirs (`-i<DIR>`)
  * Add 'clashi' program and 'clash-ghc' package [#208](https://github.com/clash-lang/clash-compiler/issues/208), thanks to @thoughtpolice
* Fixes bugs:
  * `case (EmptyCase ty) of ty' { ... }` -> `EmptyCase ty'` [#198](https://github.com/clash-lang/clash-compiler/issues/198)
  * `BitVector.split#` apply the correct type arguments

## 0.7.0.1 *January 17th 2017
* Fixes bugs:
  * Include HsVersions.h in source distribution

## 0.7 *January 16th 2017*
* New features:
  * Support for `clash-prelude` 0.11
  * Primitive templates can include QSys files
  * VHDL blackboxes: support additional libraries and uses keywords in generated VHDL
  * Highly limited Float/Double support (literals and `Rational` conversion), hidden behind the `-clash-float-support` flag.
* Fixes bugs:
  * Reduce type families inside clock period calculation [#180](https://github.com/clash-lang/clash-compiler/issues/180)
  * Only output signed literals as hex when they're multiple of 4 bits [#187](https://github.com/clash-lang/clash-compiler/issues/187)
  * Correctly print negative hex literals

## 0.6.24 *October 17th 20168
* Call generatePrimMap after loadModules [#175](https://github.com/clash-lang/clash-compiler/pull/175)
* Fixes bugs:
  * (System)Verilog: CLaSH.Sized.Vector.imap primitive gets indices in reverse order
  * Template Haskell splices are run twice
  * CLaSH errors out when observing the constructor for `Signal` [#174](https://github.com/clash-lang/clash-compiler/issues/174)

## 0.6.23 *August 18th 2015*
* Fixes bugs:
  * Type families are not being reduced correctly  [#167](https://github.com/clash-lang/clash-compiler/issues/167)
  * (System)Verilog: Fix primitives for {Signed,Unsigned} rotateL# and rotateR# [#169](https://github.com/clash-lang/clash-compiler/issues/169)

## 0.6.22 *August 3rd 2016*
* Fixes bugs:
  * Bug in DEC transformation overwrites case-alternatives
  * Bug in DEC transformation creates non-representable let-binders
  * VHDL: Incorrect primitive for `Integer`s `ltInteger#` and `geInteger#`
  * (System)Verilog: Fix primitive for CLaSH.Sized.Internal.Signed.mod# and GHC.Type.Integer.modInteger [#164](https://github.com/clash-lang/clash-compiler/issues/164)

## 0.6.21 *July 19th 2016*
* Fixes bugs:
  * Rounding error in `logBase` calculation
  * VHDL: Incorrect primitive for `Index`s `*#`
  * VHDL: Incorrect handling of `Index`s `fromInteger#` and `maxBound#` primitives for values larger than 2^MACHINE_WIDTH

## 0.6.20 *July 15th 2016*
* New features:
  * Better error location reporting
* Fixes bugs:
  * `CLaSH.Sized.Internal.Unsigned.maxBound#` not evaluated at compile-time [#155](https://github.com/clash-lang/clash-compiler/issues/155)
  * `CLaSH.Sized.Internal.Unsigned.minBound#` not evaluated at compile-time [#157](https://github.com/clash-lang/clash-compiler/issues/157)
  * Values of type Index 'n', where 'n' > 2^MACHINE_WIDTH, incorrectly considered non-synthesisable due to overflow
  * VHDL: Types in generated types.vhdl incorrectly sorted
  * Casts of CLaSH numeric types result in incorrect VHDL/Verilog (Such casts are now reported as an error)

## 0.6.19 *June 9th 2016*
* Fixes bugs:
  * `Eq` instance of `Vec` sometimes not synthesisable
  * VHDL: Converting product types to std_logic_vector fails when the `clash-hdlsyn Vivado` flag is enabled

## 0.6.18 *June 7th 2016*
* New features:
  * DEC transformation also lifts HO-primitives applied to "interesting" primitives (i.e. `zipWith (*)`)
  * New `-clash-hdlsyn Xilinx` flag to generate HDL tweaked for Xilinx synthesis tools (both ISE and Vivado)
* Fixes bugs:
  * replicate unfolded incorrectly [#150](https://github.com/clash-lang/clash-compiler/issues/150)
  * `imap` is not unrolled [#151](https://github.com/clash-lang/clash-compiler/issues/151)
  * VHDL: Incorrect primitive specification for `snatToInteger` [#149](https://github.com/clash-lang/clash-compiler/issues/149)

## 0.6.17 *April 7th 2016*
* New features:
  * Up to 2x reduced compilation times when working with large `Vec` literals
* Fixes bugs:
  * VHDL: Incorrect primitives for `BitVector`s `quot#` and `rem#`
  * VHDL: Bit indexing and replacement primitives fail to synthesise in Synopsis tools
  * Bug in DEC transformation throws CLaSH into an endless loop [#140](https://github.com/clash-lang/clash-compiler/issues/140)
  * Missed constant folding opportunity results in an error [#50](https://github.com/clash-lang/clash-prelude/issues/50)

## 0.6.16 *March 21st 2016*
* New features:
  * Also generate testbench for circuits without input ports [#135](https://github.com/clash-lang/clash-compiler/issues/135)
* Fixes bugs:
  * `clockWizard` broken [#49](https://github.com/clash-lang/clash-prelude/issues/49)

## 0.6.15 *March 15th 2016*
* Fixes bugs:
  * XST cannot finds "_types" package unless it is prefixed with "work." [#133](https://github.com/clash-lang/clash-compiler/pull/133)

## 0.6.14 *March 15th 2016*
* Fixes bugs:
  * XST cannot finds "_types" package unless it is prefixed with "work." [#133](https://github.com/clash-lang/clash-compiler/pull/133)

## 0.6.13 *March 14th 2016*
* Fixes bugs:
  * Not all lambda's in a function position removed

## 0.6.12 *March 14th 2016*
* Fixes bugs:
  * Not all lambda's in a function position removed due to bad eta-expansion [#132](https://github.com/clash-lang/clash-compiler/issues/132)

## 0.6.11 *March 11th 2016*
* New features:
  * Add support for HDL synthesis tool specific HDL generation:
    * New `-clash-hdlsyn Vivado` flag to generate HDL tweaked for Xilinx Vivado
  * Preserve more Haskell names in generated HDL [#128](https://github.com/clash-lang/clash-compiler/issues/128)
* Fixes bugs:
  * VHDL: Vivado fails to infer block ram [#127](https://github.com/clash-lang/clash-compiler/issues/127)
    * Users must use the `-clash-hdlsyn Vivado` flag in order to generate Xilinx Vivado specific HDL for which Vivado can infer block RAM.

## 0.6.10 *February 10th 2016*
* New features:
  * hdl files can be written to a directory (set by the `-clash-hdldir` flag) other than the current working directory [#125](https://github.com/clash-lang/clash-compiler/issues/125).
    Also respects the `-outputdir` directory, _unless_:
      * `-clash-hdldir` is set to a different directory.
      * `-hidir`, `-stubdir`, and `-dumbdir` are not the same directory as `-odir`
* Fixes bugs:
  * `caseCon` transformation does not work on non-exhaustive case-expressions [#123](https://github.com/clash-lang/clash-compiler/issues/123)
  * VHDL: insufficient type-qualifiers for concatenation operator [#121](https://github.com/clash-lang/clash-compiler/issues/121)
  * Primitive reductions don't look through `Signal` [#126](https://github.com/clash-lang/clash-compiler/issues/126)

## 0.6.9 *January 29th 2016*
* New features:
  * Support for `Debug.Trace.trace`, thanks to @ggreif

* Fixes bugs:
  * `case undefined of ...` should reduce to `undefined` [#116](https://github.com/clash-lang/clash-compiler/issues/109)
  * VHDL/SystemVerilog: BlockRAM elements must be bit vectors [#113](https://github.com/clash-lang/clash-compiler/issues/113)
  * Type families obscure eligibility for synthesis [#114](https://github.com/clash-lang/clash-compiler/issues/114)

## 0.6.8 *January 13th 2016*
* New features:
  * Support for Haskell's: `Char`, `Int8`, `Int16`, `Int32`, `Int64`, `Word`, `Word8`, `Word16`, `Word32`, `Word64`.
  * Int/Word/Integer bitwidth for generated HDL is configurable using the `-clash-intwidth=N` flag, where `N` can be either 32 or 64.
* Fixes bugs:
  * Cannot reduce `case error ... of ...` to `error ...` [#109](https://github.com/clash-lang/clash-compiler/issues/109)

## 0.6.7 *December 21st 2015*
* Support for `unbound-generics-0.3`
* New features:
  * Only look for 'topEntity' in the root module. [#22](https://github.com/clash-lang/clash-compiler/issues/22)
* Fixes bugs:
  * Unhelpful error message when GHC is not in PATH [#104](https://github.com/clash-lang/clash-compiler/issues/104)

## 0.6.6 *December 11th 2015*
* New features:
  * Remove all existing HDL files before generating new ones. This can be disabled by the `-clash-noclean` flag. [#96](https://github.com/clash-lang/clash-compiler/issues/96)
  * Support for `clash-prelude` 0.10.4

## 0.6.5 *November 17th 2015*
* Fixes bugs:
  * Integer literals used as arguments not always properly annotated with their type.
  * Verilog: Name collision in verilog code [#93](https://github.com/clash-lang/clash-compiler/issues/93)
  * (System)Verilog: Integer literals missing "32'sd" prefix when used in assignments.
  * VHDL: Integer literals should only be capped to 32-bit when used in assignments.
  * Verilog: HO-primitives incorrect for nested vectors.

## 0.6.4 *November 12th 2015*
* Fixes bugs:
  * Reversing alternatives is not meaning preserving for literal patterns [#91](https://github.com/clash-lang/clash-compiler/issues/91)
  * DEC: root of the case-tree must contain at least 2 alternatives [#92](https://github.com/clash-lang/clash-compiler/issues/92)
  * Do not generate overlapping literal patterns in VHDL [#91](https://github.com/clash-lang/clash-compiler/issues/91)

## 0.6.3 *October 24th 2015*
* New features:
  * Improve DEC transformation: consider alternatives before the subject when checking for disjoint expressions.
* Fixes bugs:
  * DEC: don't generate single-branch case-expressions [#90](https://github.com/clash-lang/clash-compiler/issues/90)

## 0.6.2 *October 21st 2015*
* New features:
  * Support `clash-prelude` 0.10.2

* Fixes bugs:
  * CLaSH interpreter was reading '.ghci' file instead of '.clashi' file [#87](https://github.com/clash-lang/clash-compiler/issues/87)
  * DEC: Subject and alternatives are not disjoint [#88](https://github.com/clash-lang/clash-compiler/issues/88)

## 0.6.1 *October 16th 2015*
* New features:
  * Support for `clash-prelude` 0.10.1
  * Transformation that lifts applications of the same function out of alternatives of case-statements. e.g.

    ```haskell
    case x of
      A -> f 3 y
      B -> f x x
      C -> h x
    ```

    is transformed into:

    ```haskell
    let f_arg0 = case x of {A -> 3; B -> x}
        f_arg1 = case x of {A -> y; B -> x}
        f_out  = f f_arg0 f_arg1
    in  case x of
          A -> f_out
          B -> f_out
          C -> h x
    ```

* Fixes bugs:
  * clash won't run when not compiled with usual ghc [#82](https://github.com/clash-lang/clash-compiler/issues/82)
  * Fail to generate VHDL with blockRamFile' in clash-ghc 0.6 [#85](https://github.com/clash-lang/clash-compiler/issues/85)
  * Case-statements acting like normal decoder circuits are erroneously synthesised to priority decoder circuits.

## 0.6 *October 3rd 2015*
* New features:
  * Support `clash-prelude-0.10`
  * Pattern matching on `CLaSH.Sized.Vector`'s `:>` is now supported
  * Unroll "definitions" of the following primitives: `fold`, `dfold`, `foldr`

## 0.5.15 *September 21st 2015*
* New features:
  * Report simulation time in (System)Verilog assert messages

* Fixes bugs:
  * Performance bug: top-level definitions of type "Signal" erroneously inlined.
  * Fix Index maxBound [#79](https://github.com/clash-lang/clash-compiler/pull/79)

## 0.5.14 *September 14th 2015*
* New features:
  * Completely unroll "definitions" of some higher-order primitives with non-representable argument or result vectors:
    It is now possible to translate e.g. `f xs ys = zipWith ($) (map (+) xs) ys :: Vec 4 Int -> Vec 4 Int -> Vec 4 Int`

* Fixes bugs:
  * Converting Bool to Unsigned generates broken VHDL [#77](https://github.com/clash-lang/clash-compiler/issues/77)
  * `topLet` transformation erroneously not performed in a top-down traversal
  * Specialisation limit unchecked on types and constants
  * Vector of functions cannot be translated [#25](https://github.com/clash-lang/clash-compiler/issues/25 )
  * CLaSH fails to generate VHDL when map is applied [#78](https://github.com/clash-lang/clash-compiler/issues/78)

## 0.5.13 *September 8th 2015*
* Fixes bugs:
  * Cannot translate GHC `MachLabel` literal
  * Maybe (Index n) not translatable to VHDL [#75](https://github.com/clash-lang/clash-compiler/issues/75)

## 0.5.12 *September 7th 2015*
* New features:
  * Modest compilation time speed-up. Compilation time of the [I2C](https://github.com/clash-lang/clash-compiler/tree/master/examples/i2c) module on my machine went down from 43s to 24s, and maximum memory usage went down from 840 MB to 700 MB.

* Fixes bugs:
  * Bug in VHDL ROM generation [#69](https://github.com/clash-lang/clash-compiler/issues/69)
  * Clash running out of memory on Simple-ish project [#70](https://github.com/clash-lang/clash-compiler/issues/70)
  * Fix asyncRom VHDL primitive [#71](https://github.com/clash-lang/clash-compiler/pull/71)
  * Fix primitive for CLaSH.Sized.Internal.Signed.size# [#72](https://github.com/clash-lang/clash-compiler/pull/72)
  * rem and quot on Signed are broken [#73](https://github.com/clash-lang/clash-compiler/issues/73)

## 0.5.11 *August 2nd 2015*
* New features:
  * Re-enable GHC's strictness analysis pass, which improves dead-code removal, which hopefully leads to smaller circuits.

## 0.5.10 *July 9th 2015*
* New features:
  * Use new VHDL backend which outputs VHDL-93 instead of VHDL-2002: generated VHDL is now accepted by a larger number of tools.
  * Treat all so-called bottom values (`error "FOO"`, `let x = x in x`, etc.) occuring in installed libraries as `undefined`.
    Before, there were (very) rare situations where we couldn't find the expressions belonging to a function and demanded a BlackBox, even though we knew the expression would be a bottom value.
    Now, we stop demanding a BlackBox for such a function and simply treat it as `undefined`, thus allowing a greater range of circuit descriptions that we can compile.

## 0.5.9 *June 26th 2015*
* New features:
  * Use new verilog backend which outputs Verilog-2001 instead of Verilog-2005: generated Verilog is now accepted by Altera/Quartus

* Fixes bugs:
  * `--systemverilog` switch incorrectly generates verilog code instead of systemverilog code

## 0.5.8 *June 25th 2015*
* New features:
  * Support for copying string literals from Haskell to generated code
  * Support `clash-prelude-0.9`
  * Size at below which functions are always inlined is configurable, run with `-clash-inline-below=N` to set the size limit to `N`

## 0.5.7 *June 3rd 2015*
* New features:
  * New Verilog backend, run `:verilog` in interactive mode, or `--verilog` for batch mode
  * Generated component names are prefixed by the name of the module containing the `topEntity`

## 0.5.6 *May 18th 2015*
* New features:
  * Inlining limit is configurable, run with `-clash-inline-limit=N` to set the inlining limit to `N`
  * Specialisation limit is configurable, run with `clash-spec-limit=N` to set the inline limit to `N`
  * Debug level is configurable, run with `-clash-debug <LEVEL>` where `<LEVEL>` can be: `DebugNone, DebugFinal, DebugName, DebugApplied, DebugAll`. Be default, `clash` runs with `DebugNone`.

* Fixes bugs:
  * Extend evaluator for `GHC.Integer.Type.minusInteger` and `CLaSH.Promoted.Nat.SNat`.

## 0.5.5 *May 5th 2015*
* New features:
  * `TopEntity` wrappers are now specified as `ANN` annotation pragmas [#42](https://github.com/clash-lang/clash-compiler/issues/42)

## 0.5.4 *May 1st 2015*
* New features:
  * Generate wrappers around `topEntity` that have constant names and types

## 0.5.3 *April 24th 2015*
* Fixes bugs:
  * Fix bug where not enough array type definitions were created by the VHDL backend

## 0.5.2 *April 21st 2015*
* Use latest ghc-typelits-natnormalise

## 0.5.1 *April 20th 2015*
* New features:
  * GHC 7.10 support
  * Update to clash-prelude 0.7.2
  * Use http://hackage.haskell.org/package/ghc-typelits-natnormalise typechecker plugin for better type-level natural number handling

## 0.5 *March 11th 2015*
* New features:
  * SystemVerilog backend. [#45](https://github.com/clash-lang/clash-compiler/issues/45)

## 0.4.1 *February 4th 2015*
* Include bug fixes from clash-lib 0.4.1

## 0.4 *November 17th 2014*
* New features:
  * Support for clash-prelude 0.6

* Fixes bugs:
  * clash-ghc ignores "-package-db" flag [#35](https://github.com/christiaanb/clash2/issues/35)

## 0.3.3 *August 12th 2014*
* Fixes bugs:
  * Compile with GHC 7.8.3 [#31](https://github.com/christiaanb/clash2/issues/31)

## 0.3.2 *June 5th 2014*

* Fixes bugs:
  * Type synonym improperly expanded [#17](https://github.com/christiaanb/clash2/issues/17)
  * BlackBox for `Signed` `maxBound` and `minBound` generate incorrect VHDL. [#19](https://github.com/christiaanb/clash2/issues/19)
  * Generate failure code in the VHDL for recSelError [#23](https://github.com/christiaanb/clash2/issues/23)

## 0.3.1 *May 15th 2014*

* New features:
  * Hardcode `fromInteger` for `Signed` and `Unsigned` [#9](https://github.com/christiaanb/clash2/issues/9)
  * Better blackbox operation for vindex [#12](https://github.com/christiaanb/clash2/issues/12)
  * Replace VHDL default hole by error hole [#13](https://github.com/christiaanb/clash2/issues/13)

* Fixes bugs:
  * Update GHC2Core.hs [#1](https://github.com/christiaanb/clash2/issues/1)
  * primitives (clash.sized.vector) [#2](https://github.com/christiaanb/clash2/issues/2)
  * Type families are not expanded [#3](https://github.com/christiaanb/clash2/issues/3)
  * Incorrect vhdl generation for default value in blackbox [#6](https://github.com/christiaanb/clash2/issues/6)
  * Missing begin keyword in Signed/Unsigned JSON files [#16](https://github.com/christiaanb/clash2/issues/16)
