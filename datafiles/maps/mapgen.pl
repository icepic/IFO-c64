#!/usr/bin/perl -w

print ("ff" x 32 . "\n");
for my $i (1..30) {
    print ("ff" . "00" x 30 . "ff\n" );
}
print ("ff" x 32 . "\n");

