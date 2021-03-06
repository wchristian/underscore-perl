package Underscore;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Exporter';

our @EXPORT_OK = qw(_);

use B               ();
use List::MoreUtils ();
use List::Util      ();

our $UNIQUE_ID = 0;

sub _ {
    return new(__PACKAGE__, args => [@_]);
}

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{template_settings} = {
        evaluate    => qr/<\%([\s\S]+?)\%>/,
        interpolate => qr/<\%=([\s\S]+?)\%>/
    };

    return $self;
}

sub forEach {&each}

sub each {
    my $self = shift;
    my ($array, $cb, $context) = $self->_prepare(@_);

    return unless defined $array;

    $context = $array unless defined $context;

    my $i = 0;
    foreach (@$array) {
        $cb->($_, $i, $context);
        $i++;
    }
}

sub map {
    my $self = shift;
    my ($array, $cb, $context) = $self->_prepare(@_);

    my $result = [map { $cb->($_, undef, $context) } @$array];

    return $self->_finalize($result);
}

sub contains {&include}

sub include {
    my $self = shift;
    my ($list, $value) = $self->_prepare(@_);

    if (ref $list eq 'ARRAY') {
        return (List::Util::first { $_ eq $value } @$list) ? 1 : 0;
    }
    elsif (ref $list eq 'HASH') {
        return (List::Util::first { $_ eq $value } values %$list) ? 1 : 0;
    }

    die 'WTF?';
}

sub inject {&reduce}
sub foldl  {&reduce}

sub reduce {
    my $self = shift;
    my ($array, $iterator, $memo, $context) = $self->_prepare(@_);

    die 'TypeError' if !defined $array && !defined $memo;

    # TODO
    $memo = 0 unless defined $memo;
    return $memo unless defined $array;

    foreach (@$array) {
        $memo = $iterator->($memo, $_, $context) if defined $_;
    }

    return $self->_finalize($memo);
}

sub foldr       {&reduce_right}
sub reduceRight {&reduce_right}

sub reduce_right {
    my $self = shift;
    my ($array, $iterator, $memo, $context) = $self->_prepare(@_);

    die 'TypeError' if !defined $array && !defined $memo;

    # TODO
    $memo = '' unless defined $memo;
    return $memo unless defined $array;

    foreach (reverse @$array) {
        $memo = $iterator->($memo, $_, $context) if defined $_;
    }

    return $memo;
}

sub detect {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    return List::Util::first { $iterator->($_) } @$list;
}

sub filter {&select}

sub select {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    my $result = [grep { $iterator->($_) } @$list];

    $self->_finalize($result);
}

sub reject {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    my $result = [grep { !$iterator->($_) } @$list];

    $self->_finalize($result);
}

sub every {&all}

sub all {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    foreach (@$list) {
        return 0 unless $iterator->($_);
    }

    return 1;
}

sub some {&any}

sub any {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    return 0 unless defined @$list;

    foreach (@$list) {
        return 1 if $iterator ? $iterator->($_) : $_;
    }

    return 0;
}

sub invoke {
    my $self = shift;
    my ($list, $method, @args) = $self->_prepare(@_);

    my $result = [];

    foreach (@$list) {
        push @$result,
          [ref $method eq 'CODE' ? $method->(@$_) : $self->$method(@$_)];
    }

    return $result;
}

sub pluck {
    my $self = shift;
    my ($list, $key) = $self->_prepare(@_);

    my $result = [];

    foreach (@$list) {
        push @$result, $_->{$key};
    }

    return $result;
}

sub max {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    return List::Util::max(@$list) unless defined $iterator;

    return List::Util::max(map { $iterator->($_) } @$list);
}

sub min {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    return List::Util::min(@$list) unless defined $iterator;

    return List::Util::min(map { $iterator->($_) } @$list);
}

sub sortBy {&sort_by}

sub sort_by {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    my $result = [sort { $a cmp $iterator->($b) } @$list];

    return $self->_finalize($result);
}

sub reverse : method {
    my $self = shift;
    my ($list) = $self->_prepare(@_);

    my $result = [reverse @$list];

    return $self->_finalize($result);
}

sub concat {
    my $self = shift;
    my ($list, $other) = $self->_prepare(@_);

    my $result = [@$list, @$other];

    return $self->_finalize($result);
}

sub unshift : method {
    my $self = shift;
    my ($list, @elements) = $self->_prepare(@_);

    unshift @$list, @elements;
    my $result = $list;

    return $self->_finalize($result);
}

sub pop : method {
    my $self = shift;
    my ($list) = $self->_prepare(@_);

    pop @$list;
    my $result = $list;

    return $self->_finalize($result);
}

sub groupBy {&group_by}

sub group_by {
    my $self = shift;
    my ($list, $iterator) = $self->_prepare(@_);

    # TODO
}

sub sortedIndex {&sorted_index}

sub sorted_index {
    my $self = shift;
    my ($list, $value, $iterator) = $self->_prepare(@_);

    # TODO $iterator

    my $min = 0;
    my $max = @$list;
    my $mid;

    do {
        $mid = int(($min + $max) / 2);
        if ($value > $list->[$mid]) {
            $min = $mid + 1;
        }
        else {
            $max = $mid - 1;
        }
    } while ($list->[$mid] == $value || $min > $max);

    if ($list->[$mid] == $value) {
        return $mid;
    }

    return $mid + 1;
}

sub toArray {&to_array}

sub to_array {
    my $self = shift;
    my ($list) = $self->_prepare(@_);

    return [values %$list] if ref $list eq 'HASH';

    return [$list] unless ref $list eq 'ARRAY';

    return [@$list];
}

sub size {
    my $self = shift;
    my ($list) = $self->_prepare(@_);

    return scalar @$list if ref $list eq 'ARRAY';

    return scalar keys %$list if ref $list eq 'HASH';

    return 1;
}

sub first {
    my $self = shift;
    my ($array, $n) = $self->_prepare(@_);

    return $array->[0] unless defined $n;

    return [@{$array}[0 .. $n - 1]];
}

sub tail {&rest}

sub rest {
    my $self = shift;
    my ($array, $index) = $self->_prepare(@_);

    $index = 1 unless defined $index;

    return [@{$array}[$index .. $#$array]];
}

sub last {
    my $self = shift;
    my ($array) = $self->_prepare(@_);

    return $array->[-1];
}

sub compact {
    my $self = shift;
    my ($array) = $self->_prepare(@_);

    my $new_array = [];
    foreach (@$array) {
        push @$new_array, $_ if $_;
    }

    return $new_array;
}

sub flatten {
    my $self = shift;
    my ($array) = $self->_prepare(@_);

    my $cb;
    $cb = sub {
        my $result = [];
        foreach (@{$_[0]}) {
            if (ref $_ eq 'ARRAY') {
                push @$result, @{$cb->($_)};
            }
            else {
                push @$result, $_;
            }
        }
        return $result;
    };

    my $result = $cb->($array);

    return $self->_finalize($result);
}

sub without {
    my $self = shift;
    my ($array, @values) = $self->_prepare(@_);

    # Nice hack comparing hashes

    my $new_array = [];
    foreach my $el (@$array) {
        push @$new_array, $el
          unless defined List::Util::first { $el eq $_ } @values;
    }

    return $new_array;
}

sub uniq {
    my $self = shift;
    my ($array, $is_sorted) = $self->_prepare(@_);

    return [List::MoreUtils::uniq(@$array)] unless $is_sorted;

    # We can push first value to prevent unneeded -1 check
    my $new_array = [shift @$array];
    foreach (@$array) {
        push @$new_array, $_ unless $_ eq $new_array->[-1];
    }

    return $new_array;
}

sub intersection {
    my $self = shift;
    my (@arrays) = $self->_prepare(@_);

    my $seen = {};
    foreach my $array (@arrays) {
        $seen->{$_}++ for @$array;
    }

    my $intersection = [];
    foreach (keys %$seen) {
        push @$intersection, $_ if $seen->{$_} == @arrays;
    }
    return $intersection;
}

sub union {
    my $self = shift;
    my (@arrays) = $self->_prepare(@_);

    my $seen = {};
    foreach my $array (@arrays) {
        $seen->{$_}++ for @$array;
    }

    return [keys %$seen];
}

sub difference {
    my $self = shift;
    my ($array, $other) = $self->_prepare(@_);

    my $new_array = [];
    foreach my $el (@$array) {
        push @$new_array, $el unless List::Util::first { $el eq $_ } @$other;
    }

    return $new_array;
}

sub zip {
    my $self = shift;
    my (@arrays) = $self->_prepare(@_);

    # This code is from List::MoreUtils
    # (can't use it here directly because of the prototype!)
    my $max = -1;
    $max < $#$_ && ($max = $#$_) foreach @arrays;
    return [
        map {
            my $ix = $_;
            map $_->[$ix], @_;
          } 0 .. $max
    ];

}

sub indexOf {&index_of}

sub index_of {
    my $self = shift;
    my ($array, $value, $is_sorted) = $self->_prepare(@_);

    return -1 unless defined $array;

    return List::MoreUtils::first_index { $_ eq $value } @$array;
}

sub lastIndexOf {&last_index_of}

sub last_index_of {
    my $self = shift;
    my ($array, $value, $is_sorted) = $self->_prepare(@_);

    return -1 unless defined $array;

    return List::MoreUtils::last_index { $_ eq $value } @$array;
}

sub range {
    my $self = shift;
    my ($start, $stop, $step) =
      @_ == 3 ? @_ : @_ == 2 ? @_ : (undef, @_, undef);

    return [] unless $stop;

    $start = 0 unless defined $start;

    return [$start .. $stop - 1] unless defined $step;

    my $new_array = [];
    while ($start < $stop) {
        push @$new_array, $start;
        $start += $step;
    }
    return $new_array;
}

sub mixin {
    my $self = shift;
    my (%functions) = $self->_prepare(@_);

    no strict 'refs';
    no warnings 'redefine';
    foreach my $name (keys %functions) {
        *{__PACKAGE__ . '::' . $name} = sub {
            my $self = shift;

            unshift @_, @{$self->{args}}
              if defined $self->{args} && @{$self->{args}};
            $functions{$name}->(@_);
        };
    }
}

sub uniqueId {&unique_id}

sub unique_id {
    my $self = shift;
    my ($prefix) = $self->_prepare(@_);

    $prefix = '' unless defined $prefix;

    return $prefix . ($UNIQUE_ID++);
}

sub times {
    my $self = shift;
    my ($n, $iterator) = $self->_prepare(@_);

    for (0 .. $n - 1) {
        $iterator->($_);
    }
}

sub template_settings {
    my $self = shift;
    my (%args) = @_;

    for (qw/interpolate evaluate/) {
        if (my $value = $args{$_}) {
            $self->{template_settings}->{$_} = $value;
        }
    }
}

sub template {
    my $self = shift;
    my ($template) = $self->_prepare(@_);

    my $evaluate    = $self->{template_settings}->{evaluate};
    my $interpolate = $self->{template_settings}->{interpolate};

    return sub {
        my ($args) = @_;

        my $code = q!sub {my ($args) = @_; my $_t = '';!;
        foreach my $arg (keys %$args) {
            $code .= "my \$$arg = \$args->{$arg};";
        }

        $template =~ s{$interpolate}{\}; \$_t .= $1; \$_t .= q\{}g;
        $template =~ s{$evaluate}{\}; $1; \$_t .= q\{}g;

        $code .= '$_t .= q{';
        $code .= $template;
        $code .= '};';
        $code .= 'return $_t};';

        my $sub = eval $code;

        return $sub->($args);
    };
}

our $ONCE;

sub once {
    my $self = shift;
    my ($func) = @_;

    return sub {
        return if $ONCE;

        $ONCE++;
        $func->(@_);
    };
}

sub wrap {
    my $self = shift;
    my ($function, $wrapper) = $self->_prepare(@_);

    return sub {
        $wrapper->($function, @_);
    };
}

sub compose {
    my $self = shift;
    my (@functions) = @_;

    return sub {
        my @args = @_;
        foreach (reverse @functions) {
            @args = $_->(@args);
        }

        return wantarray ? @args : $args[0];
    };
}

sub bind {
    my $self = shift;
    my ($function, $object, @args) = $self->_prepare(@_);

    return sub {
        $function->($object, @args, @_);
    };
}

sub keys : method {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';

    return [keys %$object];
}

sub values {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';

    return [values %$object];
}

sub functions {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';

    my $functions = [];
    foreach (keys %$object) {
        push @$functions, $_
          if ref $object->{$_} && ref $object->{$_} eq 'CODE';
    }
    return $functions;
}

sub extend {
    my $self = shift;
    my ($destination, @sources) = $self->_prepare(@_);

    foreach my $source (@sources) {
        foreach my $key (keys %$source) {
            next unless defined $source->{$key};
            $destination->{$key} = $source->{$key};
        }
    }

    return $destination;
}

sub defaults {
    my $self = shift;
    my ($object, @defaults) = $self->_prepare(@_);

    foreach my $default (@defaults) {
        foreach my $key (keys %$default) {
            next if exists $object->{$key};
            $object->{$key} = $default->{$key};
        }
    }

    return $object;
}

sub clone {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    # Scalars will be copied, everything deeper not
    my $cloned = {};
    foreach my $key (keys %$object) {
        $cloned->{$key} = $object->{$key};
    }

    return $cloned;
}

sub isEqual {&is_equal}

sub is_equal {
    my $self = shift;
    my ($object, $other) = $self->_prepare(@_);
}

sub isEmpty {&is_empty}

sub is_empty {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 1 unless defined $object;

    if (!ref $object) {
        return 1 if $object eq '';
    }
    elsif (ref $object eq 'HASH') {
        return 1 if !(keys %$object);
    }
    elsif (ref $object eq 'ARRAY') {
        return 1 if @$object == 0;
    }
    elsif (ref $object eq 'Regexp') {
        return 1 if $object eq qr//;
    }

    return 0;
}

sub isArray {&is_array}

sub is_array {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 1 if defined $object && ref $object && ref $object eq 'ARRAY';

    return 0;
}

sub isString {&is_string}

sub is_string {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 0 unless defined $object && !ref $object;

    return 0 if $self->is_number($object);

    return 1;
}

sub isNumber {&is_number}

sub is_number {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 0 unless defined $object && !ref $object;

    # From JSON::PP
    my $flags = B::svref_2object(\$object)->FLAGS;
    my $is_number = $flags & (B::SVp_IOK | B::SVp_NOK)
      and !($flags & B::SVp_POK) ? 1 : 0;

    return 1 if $is_number;

    return 0;
}

sub isFunction {&is_function}

sub is_function {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 1 if defined $object && ref $object && ref $object eq 'CODE';

    return 0;
}

sub isRegExp {&is_regexp}

sub is_regexp {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 1 if defined $object && ref $object && ref $object eq 'Regexp';

    return 0;
}

sub isUndefined {&is_undefined}

sub is_undefined {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 1 unless defined $object;

    return 0;
}

sub chain {
    my $self = shift;

    $self->{chain} = 1;

    return $self;
}

sub value {
    my $self = shift;

    return wantarray ? @{$self->{args}} : $self->{args}->[0];
}

sub _prepare {
    my $self = shift;
    unshift @_, @{$self->{args}} if defined $self->{args} && @{$self->{args}};
    return @_;
}

sub _finalize {
    my $self = shift;

    return
        $self->{chain} ? do { $self->{args} = [@_]; $self }
      : wantarray      ? @_
      :                  $_[0];
}

1;
