class Range is Iterable {
    has $.min;
    has $.max;
    has $.excludes_min;
    has $.excludes_max;

    proto method new(|$) { * }
    multi method new($min, $max, :$excludes_min, :$excludes_max) {
        my $new = self.CREATE;
        $new.BUILD($min, $max, $excludes_min, $excludes_max)
    }
    multi method new($min, Whatever $max, :$excludes_min, :$excludes_max) {
        my $new = self.CREATE;
        $new.BUILD($min, $Inf, $excludes_min, $excludes_max)
    }

    method BUILD($min, $max, $excludes_min, $excludes_max) {
        $!min = $min;
        $!max = $max;
        $!excludes_min = $excludes_min;
        $!excludes_max = $excludes_max;
        self;
    }

    method infinite() { $.max == $Inf }
    method iterator() { self }

    method reify($n is copy = 10) {
        $n = $Inf if Whatever.ACCEPTS($n);
        fail "request for infinite elements from range"
          if $n == $Inf && self.infinite;
        my $value = $!excludes_min ?? $!min.succ !! $!min;
        my $cmpstop = $!excludes_max ?? 0 !! 1;
        my Mu $rpa := pir::new__Ps('ResizablePMCArray');
        (pir::push__vPP($rpa, $value++); $n--)
          while $n > 0 && ($value cmp $!max) < $cmpstop;
        ($value cmp $!max) < $cmpstop
            && pir::push__vPP($rpa,
                   ($value.succ cmp $!max < $cmpstop)
                      ?? self.CREATE.BUILD($value, $!max, 0, $!excludes_max)
                      !! $value);
        pir__perl6_box_rpa__PP($rpa)
    }

    multi method gist(Range:D:) { self.perl }
    multi method perl(Range:D:) { 
        $.min 
          ~ ('^' if $.excludes_min)
          ~ '..'
          ~ ('^' if $.excludes_max)
          ~ $.max
    }
}


###  XXX remove the (1) from :excludes_min and :excludes_max below
sub infix:<..>($min, $max) { 
    Range.new($min, $max) 
}
sub infix:<^..>($min, $max) { 
    Range.new($min, $max, :excludes_min(1)) 
}
sub infix:<..^>($min, $max) { 
    Range.new($min, $max, :excludes_max(1)) 
}
sub infix:<^..^>($min, $max) {
    Range.new($min, $max, :excludes_min(1), :excludes_max(1)) 
}
sub prefix:<^>($max) {
    Range.new(0, $max, :excludes_max(1)) 
}
