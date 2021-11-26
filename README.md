# Examples of fypp

Fortran用のメタプログラミングツール[fypp](https://github.com/aradi/fypp)の使用例．

## 要求ソフトウェア
- fypp

## ビルド
このプロジェクトはコード生成の例を提供するため，ビルドは不要である．
生成されたコードがビルドできることを確認する目的でコードテンプレートを配置している．テンプレート（`.fy90`）からソースファイル（`.f90`）を生成するスクリプトなどは用意されていないので，ビルドしたいソースファイルは，一つずつ手動で生成する必要がある．

ビルドには下記コマンドを実行する．
```console
fpm build
```
このとき，`is_positive.fy90`および`mean.fy90`から生成されるソースがないとビルドが正常に行われない．

`macro.fypp`から生成されるソース`macro.f90`がビルドに含まれる場合には，プリプロセスを有効にするオプションを付与する．
```console
fpm build --flag "-cpp"
```

Intel Fortranを用いる場合には，コンパイラを選択するオプションも併せて付与する．

```console
fpm build --compiler ifort --flag "/fpp"
```

## 実行
このプロジェクトは，例（example）として複数の実行ファイルを作成する．それらの例を実行するには，下記のようなコマンドを実行する．
```console
fpm run --flag "-cpp" --example 実行ファイル
```

例としてどのような実行ファイルが作られているかは，`--list`オプションを利用する．
```console
fpm run --flag "-cpp" --example --list
```
```console
> fpm run --flag "-cpp" --example --list
 Matched names:
example           for               ifdef             ifdef_inline
macro             val
> fpm run --flag "-cpp" --example example
 F
 T
   5.0000000000000000        10.000000000000000        15.000000000000000
```

## fyppの使用例
### プロジェクトの構造
fpmのプロジェクト構造に沿っている．以降の作業は全てカレントディレクトリ（`.`）で行う．

```
.
├── example
│   ├── example.f90
│   ├── for.fy90
│   ├── ifdef_inline.fy90
│   ├── ifdef.fy90
│   ├── macro.fy90
│   └── val.fy90
├── src
│   ├── inc
│   │   └── common.fypp
│   ├── is_positive.fy90
│   └── mean.fy90
├── .gitignore
├── fpm.toml
└── README.md
```

### fyppの実行
fyppの実行オプションとして，テンプレートファイル名と生成されるソースファイル名を指定する．

```console
fypp テンプレート ソース
```

複数のテンプレートを入力し，複数のソースファイルを出力することはできない．

### 識別子の定義と分岐
fyppで分岐を表現するには，`#:if`ディレクティブを用いる．識別子が定義されているかを判定するには，`defined`命令を用いる．
`#:if`と`defined`の組合せは`.\example\ifdef.fy90`で確認できる．

```Fortran
    #:if defined('DEBUG')
        print *, "debug print"
    #:else
        print *,"release"
    #:endif
```

識別子は，`--definle=識別子`オプションを利用して定義する．
```console
cd example
fypp ifdef.fy90 ifdef.f90 --define=DEBUG
```
上記の場合，`example\ifdef.90`内には`print *, "debug print"`が埋め込まれ，`--define=DEBUG`オプションを付けない場合は，`print *,"release"`が埋め込まれる．

分岐は1行で書くこともでき，その例は`.\example\ifdef_inline.fy90`で確認できる．

```Fortran
    #{if defined('DEBUG')}# print *,"debug" #{else}# print *,"release" #{endif}#
```

例の`DEBUG`は便宜上識別子と呼んでいたが，fyppの識別子は正確には値の変わらない変数（定数）であり，値を参照したり，削除したりできる．

`.\example\val.fy90`にその例を作成している．定数`NUM_GRID_POINTS`の値を`#:if`ディレクティブ内で参照している．プログラム中にその値を反映するには，`${}$`を利用する．
また，利用しなくなった変数は`#:del`で削除できる．
```Fortran
    #:if defined('NUM_GRID_POINTS') and NUM_GRID_POINTS > 0
        integer(int32), parameter :: Nx = ${NUM_GRID_POINTS}$
    #:else
        integer(int32), parameter :: Nx = 100
    #:endif
    #:if defined('NUM_GRID_POINTS')
        #:del NUM_GRID_POINTS
    #:endif
```

コンパイル時に定数の値を定めるには，コンパイルオプションとして`--define=定数=値`を用いる．
```console
cd example
fypp val.fy90 val.f90 --define=NUM_GRID_POINTS=10
```

### マクロ
Cプリプロセッサでは複数行のマクロの定義は基本的にできなかったが，fyppでは複数行からなるマクロを自然に定義できる．

`.\example\macro.fy90`には，Cプリプロセッサの`__FILE__`, `__LINE__`と組み合わせたアサーションのマクロが例示されている．
```Fortran
    #:def ASSERT(cond)
        if (.not. ${cond}$) then
            write (error_unit, '(3A,I0,A)') "assertion failed: ", __FILE__, ", line ", __LINE__, "."
            error stop
        end if
    #:enddef ASSERT

    integer(int32) :: result
    result = 1 + 1

    @:ASSERT(result == 3)
```

マクロの定義には`#:def`を用い，マクロを参照するには，`@:マクロ名(引数)`あるいは`$:マクロ名("引数")`を用いる．

```console
cd example
fypp macro.fy90 macro.f90
```
でコードを生成すると，マクロが展開されている．このコードをビルドするには，Cプリプロセッサを処理するオプションが必要である．

```Fortran
        if (.not. result == 3) then
            write (error_unit, '(3A,I0,A)') "assertion failed: ", __FILE__, ", line ", __LINE__, "."
            error stop
        end if
```

### 変数の定義と繰り返し処理
`#:for`ディレクティブを用いると，繰り返し処理が行われ，その繰返し回数だけコードが展開される．この機能と変数を利用することで，より柔軟にコードを生成できる．

下記は，`.\example\for.fy90`の内容である．
```Fortran
    #! integer kinds
    #:set INTEGER_KINDS = ['int8', 'int16', 'int32', 'int64']

    #:for int_kind in INTEGER_KINDS
        integer(${int_kind}$), parameter :: zero_${int_kind}$ = 0_${int_kind}$
    #:endfor
```
ここでは，`#:set`ディレクティブを用いて`'int8', 'int16', 'int32', 'int64'`を値に持つ変数`INTEGER_KINDS`を定義している．その後，`#:for`ディレクティブを利用して，`INTEGER_KINDS`の値を一つずつ取り出し，コード内に埋め込んでいる．

```console
cd example
fypp for.fy90 for.f90
```
```Fortran
        integer(int8), parameter :: zero_int8 = 0_int8
        integer(int16), parameter :: zero_int16 = 0_int16
        integer(int32), parameter :: zero_int32 = 0_int32
        integer(int64), parameter :: zero_int64 = 0_int64
```

### 外部ファイルの読み込み
`INTEGER_KINDS`のような変数は，複数のコードから参照される可能性がある．コードの中で繰り返し定義することを避け，一箇所にまとめておいて，それを複数のファイルか参照した方がと効率がよい．

外部からファイルを読み込み，内容をコード内に埋め込むには`#:include`ディレクティブを利用する．

```Fortran
#:include "common.fypp"
```
ファイルはカレントディレクトリから探索される．カレントディレクトリ以外にファイルを置いた場合は，`--include=インクルードディレクトリ`オプションを利用して，ファイルを探索するパスを指定する．

`common.fypp`は`.\src\inc`に置かれており，`.\src\is_positive.fy90`および`.\src\mean.fy90`に参照されている．
```console
cd src
fypp is_positive.fy90 is_positive.f90 --include=inc
```

### 手続テンプレート
Fortranは，総称名を利用する事で，同じ名前で異なる型の引数を取る手続を定義できる．しかし，それを実現するには，異なる型に対して同じ処理を何回も書く必要があった．

型をfyppの変数として`common.fypp`に定義し，それらを参照する手続テンプレートを作成することで，異なる型に対して同じ処理を行う手続を生成できる．

```Fortran
    #:for k, t in IR_KINDS_TYPES

        logical function is_positive_${k}$(val)
            implicit none
            ${t}$, intent(in) :: val

            is_positive_${k}$ = .false.
            if (val >= 0${decimal_suffix(t)}$_${k}$) then
                is_positive_${k}$ = .true.
            end if
        end function is_positive_${k}$
    #:endfor
```
`IR_KINDS_TYPES`は，整数型および実数型の種別（kind）と型名を持つリストであり，`.\src\inc\common.fypp`内で定義されている．

```console
cd src
fypp is_positive.fy90 is_positive.f90 --include=inc
```
fyppでコードを生成すると，それぞれ`int8`, `int16`, `int32`, `int64`, `real32`, `real64`を引数に取る個別の関数`is_positive`が生成される．

`decimal_suffix(t)`はマクロであり，文字列`t`の中に`real`があれば`.0`を返し，それ以外は何も返さない．引数の型が実数の場合に，`0`を`0.0`と表現するために導入されている．

```Fortran
#:def decimal_suffix(type)
#{if 'real' in type}#.0#{endif}#
#:enddef
```

マクロを関数のように呼ぶ方法を理解すると，変数の型だけでなく異なるrankの配列を引数に取る手続テンプレートも作成できる．`.\src\mean.fypp`はその例である．

```Fortran
    #:for rank in range(1, 15+1)
        function mean_r64_rank${rank}$(x) result(res)
            real(real64), intent(in) :: x${rank_suffix(rank)}$
            real(real64) :: res

            res = sum(x) / real(size(x, kind = int64), real64)

        end function mean_r64_rank${rank}$
    #:endfor
```

`#:for rank in range(1, 15+1)`でrankを1から15まで変化させ，`${rank_suffix(rank)}$`でrankに応じた数のコロン`(:), (:,:),...`を埋め込んでいる．
```console
cd src
fypp mean.fy90 mean.f90 --include=inc
```
を実行すると，1～15までの配列ランクを持つ倍精度実数配列を引数に取る関数`mean`が作成される．

## 参考
[Fortran用メタプログラミングツールfyppの使い方](https://qiita.com/implicit_none/items/47680973fb98d85d6cbb)