
###                                                                 ###
# Class::ArrayObjects - Utility class for array based objects         #
# Robin Berjon <robin@knowscape.com>                                  #
# ------------------------------------------------------------------- #
# 21/04/2001 - v0.04 many many documentation updates + release        #
# 02/04/2001 - v0.03 feature upgrade in view of release               #
# 28/01/2001 - v0.02 a few enhancements and uses                      #
# 12/12/2000 - v0.01 initial hack                                     #
###                                                                 ###


package Class::ArrayObjects;

use strict;
no  strict 'refs';
use vars qw($VERSION %packages);

$VERSION = '0.04';


#---------------------------------------------------------------------#
# import()
# this is where all the work gets done, at load
#---------------------------------------------------------------------#
sub import {
    my $class = shift;
    @_ or return;

    my $pkg = caller;
    my $method = shift;
    my $options = shift;

    ### grab the start index and the fields
    my ($idx, @fld, @real_fld);

    # for basic definition
    if ($method eq 'define') {
        $idx = 0;
        @fld = @{$options->{fields}};
        @real_fld = @fld;
    }

    # for extension
    elsif ($method eq 'extend') {
        die "[$pkg]: can't extend undefined class $options->{class} with package $pkg"
            unless defined $packages{$options->{class}};

        # get what is needed to store the real idx
        @real_fld = (@{$packages{$options->{class}}}, @{$options->{with}});

        # support import of parent fields
        if ($options->{import}) {
            $idx = 0;
            @fld = @real_fld;
        }
        else {
            $idx = $#{$packages{$options->{class}}} + 1;
            @fld = @{$options->{with}};
        }
    }

    # there was an error
    else {
        die "[$pkg]: first arg must be 'define' or 'extend'";
    }

    # now lets create the subs
    for my $enum (@fld) {
        my $qname = "${pkg}::$enum";
        my $value = $idx;
        *$qname = sub () { $value };
        $idx++;

        # another way of doing it:
        # eval "sub ${pkg}::$enum () { $idx }";
        # die "[$pkg]: $@" if $@;
        # $idx++
    }
    $packages{$pkg} = \@real_fld; # store the fields for extension
    return 1;
}
#---------------------------------------------------------------------#



1;
=pod

=head1 NAME

Class::ArrayObjects - utility class for array based objects

=head1 SYNOPSIS

  package Some::Class;
  use Class::ArrayObjects define => {
                                      fields  => [qw(_foo_ _bar_ BAZ)],
                                    };

  or

  package Other::Class;
  use base 'Some::Class';
  use Class::ArrayObjects extend => {
                                      class   => 'Some::Class',
                                      with    => [qw(_zorg_ _fnord_ BEZ)],
                                      import  => 1,
                                    };

=head1 DESCRIPTION

This module is little more than a cute way of defining constant subs
in your own package. Constant subs are very useful when dealing with
array based objects because they allow one to access array slots by
name instead of by index.

=head2 Why use arrays for objects instead of hashes ?

There are two apparently compelling reasons to use arrays for objects
instead of hashes.

First: speed. In my benchmarks on a few boxes around here I've seen
arrays be faster by 30%. I must admit that my benchmarks weren't
perfect as I wasn't all that interested in speed per se, only in
knowing whether I was to take a serious performance hit or not (I was
nevertheless pleasantly surprised to note the opposite, it can't
hurt).

Second: memory. Memory was much more important to me as I was
targeting a mod_perl environment, where every bit of memory tends to
count (so long as it doesn't take too much programming time).
Depending on how they are used, arrays use from 30% up to 65% less
space than hashes. As a rule of thumb the more keys you have, the more
you may save.

It must be said though that despite the fact that I happened to be
looking for ways to save space, it's not a reason to jump into array
based objects and start converting every single hash you have to an
array. Yes, I did see some of my processes lose B<3.2Mo> of unshared
memory so there are definitely cases when it's useful. Such cases are
usually when you have lots of objects and/or structures that are
fairly similar in nature (ie have the same keys) but contain different
values. I don't know how Perl works internally but it would seem only
logical that it has to store the keys with every hash, whereas using
arrays there are no keys (which is why this package exists: to provide
you with something that looks like keys into arrays).

In addition to that, this package can be seen as twisting slightly the
view on how to do OO in Perl, encouraging some limited encapsulation
of fields and extension subclassing rather than override subclassing
(the latter really being a matter of taste).

=head2 Why not pseudo-hashes ?

Pseudo-hashes never appealed to me, they always seemed to have been
hacked on top of Perl. They never left experimental status, which
probably says a lot already. A number of things that work with hashes
and arrays don't work with them (and development seems to have
stopped). And overall, they usually end up not saving you any space
anyway. Pseudo-hashes must die.

=head2 Why Class::ArrayObjects ?

But why then use this class instead of the C<enum> or C<constant>
modules ? Because it adds extra sugar (yum).

Its main advantage over C<constant> (imho of course) is that you don't
have to define the value of each field. Less typing, more readability.

C<enum> also provides that plus but it enforces naming rules in a
way which I find limiting (it probably has very good reasons to do so,
but I think that they don't apply in the context of array based
objects). This module only complains if you try to use a field name
that isn't a valid Perl sub name. (Note: right now it doesn't even
complain because I was convinced when I wrote it that Perl would. But
it turns out that you are perfectly allowed to define a sub with a
forbidden name. Whether this is a bug or a feature, I don't know).

And last but not least, it defines a way to allow for inheritance
while using array based objects. A major drawback of array based
objects is that unlike with hashes, if your base class adds a field,
you have to move all your fields' indices up by one. You shouldn't
have to know such things, or even to care about it.

Here, instead of using the C<define> pragma (which creates fields in
a class), simply use the C<extend> pragma. Tell it which class to
extend (it needs to be already loaded, and must use
Class::ArrayObjects to define its fields too) and which fields to add.
Class::ArrayObjects takes care of counting from the right index in
your subclass. The next version will also add multiple inheritance.

You may use the C<import> option to require that your parents' fields
be defined in your own package too, so that you can access them. It is
off by default so that you can use fields with the same names as those
of your superclasse(s) (which is a plus over hash based objects) and
also to avoid defining subs all over your package without you knowing
about it.

It may be worth noting that the added functionality doesn't get in the
way, and using this to define constants is just as fast as using
C<constant> or C<enum>.

=head1 USING Class::ArrayObjects

There are two ways to use Class::ArrayObjects, either to simply define
fields to use in your own objects, or to extend fields defined in a
superclass of your. In a wild burst of creative naming I thus spawned
into existence two pragmata (not to be confused with those of Perl)
named respectively B<define> and B<extend>.

The way the two pragmata are used is the same:

use Class::ArrayObjects I<pragma> => I<hashref of options>

=head2 The define pragma

  package Some::Class;
  use Class::ArrayObjects define => {
                                      fields  => [qw(_foo_ _bar_ BAZ)],
                                    };

The C<define> pragma has only one option: C<fields>. It is an arrayref
of strings which are the names of the fields you wish to use. They can
be anything, so long as they are valid Perl sub names.

=head2 The extend pragma

  package Other::Class;
  use base 'Some::Class';
  use Class::ArrayObjects extend => {
                                      class   => 'Some::Class',
                                      with    => [qw(_zorg_ _fnord_ BEZ)],
                                      import  => 1,
                                    };

The C<extend> pragma has only three options:

=over 4

=item * class

This defines the class to extend (it must also use Class::ArrayObjects
and have been loaded previously).

=item * with

This is exactly equivalent to C<fields> except that it reads better to
have extend class Foo with x,y,z.

=item * import

Defaulting to false, setting it to any true value will make your
superclasses' fields also defined in your package. This can be needed
at times, though I wouldn't encourage its use.

=back

=head2 After that ?

After you've defined fields, all you have to do is use them as indices
to your arrays.

  package Some::Class;
  use Class::ArrayObjects define => {
                                      fields  => [qw(_foo_ _bar_ BAZ)],
                                    };

  my @arry = qw(zorg stuff blurp);
  print $arry[_bar_]; # prints stuff

Any operation you can do on arrays with numeric indices works exactly
the same way. The only difference is that you are using names, which
are much easier to remember. There is no performance penalty for this,
Perl is smart enough to inline the return values of constant subs so
that when in the above example you say _bar_ it really sees 1.

=head2 A note to mod_perl users

The contexts in which I use this module are mostly mod_perl related.
In fact, one of the reasons I created it was to allow for the space
efficient representation of many objects. It may be further
optimizable, but so far it has already seemed to work well.

You can preload this module without defining any fields as follows:

  use Class::ArrayObjects qw();

In that case, C<import()> will not be called and nothing will happen
other then the preloading of the code. As a precaution, even if it
were called it will return immediately.

I do recommend that you preload all modules that are based on
Class::ArrayObjects so that the data it stores internally about which
fields belong to which classes (in order to allow for extension)
remains shared by all the processes.

=head1 BUGS AND CAVEATS

I don't know of any outstanding bugs presently but it is not
impossible that some may have filtered out. I have been using this
module in production for some time now, and it appears to be behaving
with stability.

Of course, you mustn't define a field in your package with the same
name as another sub.

This version isn't really polished, and lacks a few features which I'd
like to add in the future. Most of those features (notably multiple
inheritance) are only a matter of a few lines of code but I needed to
get this module out fast in order to be able to release other modules
which I've been developing. The other features will get added
according to the whims of user requests, my own personal needs in the
context of my other modules, and of course whenever I may be bored
(which unfortunately isn't anywhere near as often as I'd like to)

This approach doesn't play well with polymorphism if you access fields
directly. In general, polymorphism should really be done through
accessors so that isn't a problem imho.

As a rule of thumb, I find that this kind of class works better for
extension subclasses than for override subclasses, but YMMV.

=head1 TODO

 - add multiple inheritance
 - cleanup coding style
 - add an interface to allow people to mess with the internals on
 demand
 - add serialisation helpers to allow one to persist an object based
 on Class::ArrayObjects and later retrieve it regardless of whether
 the order of the fields have changed or not.

=head1 ACKNOWLEDGMENTS

While I was looking for ways to reduce the memory consumption of my
apps without losing too much speed I recalled an old TPJ article
precisely about that. I read it, found it very interesting, and then
the project I was working on changed so I forgot about it.

Later on, I came back to reducing memory, and hacked a bare-bones
version of this module. I'd forgotten about the article and was
working with notes I'd taken about various ideas I had.

Prior to releasing this module, I remembered the article but can't go
check it out to acknowledge the author until tpj.com is back online
(hopefully very soon !). I think the author mentioned having released
a module similar to this one to CPAN, but I couldn't find anything
there (searching for array, object, and class). If you remember who
that was, please let me know so that his glorious name may appear in
these small tables.

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut
