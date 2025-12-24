#![feature(test)]
extern crate test;

#[bench]
fn dummy_bench(b: &mut test::Bencher) {
    b.iter(|| 2 + 2);
}
