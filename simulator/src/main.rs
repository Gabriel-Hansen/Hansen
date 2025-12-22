
mod isa;
mod memory;
mod core;
mod driver;
mod kernels;

use crate::driver::AcceleratorDriver;
use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 2 {
        println!("Usage: {} <command> [args]", args[0]);
        println!("Commands:");
        println!("  simple      Run simple sum test");
        println!("  particles   Run particle simulation");
        println!("     --json   Output results in JSON format");
        return;
    }

    let command = &args[1];
    let json_mode = args.contains(&"--json".to_string());
    
    let mut driver = AcceleratorDriver::new();

    if !json_mode {
        println!("--- Hansen Accelerator Driver (Mock) ---");
        println!("Device Initialized: 64KB Local Memory");
    }

    match command.as_str() {
        "particles" => {
             // In a real game loop, we'd run this 60 times a second.
             // Here we simulate 10 frames of updates.
             
             let kernel = kernels::get_particle_sim_kernel();
             
             // Init Particles
             let particle_count = 10;
             let mut initial_data = Vec::new();
             for i in 0..particle_count {
                 let val: u32 = i * 10;
                 initial_data.push((val & 0xFF) as u8);
                 initial_data.push(((val >> 8) & 0xFF) as u8);
                 initial_data.push(((val >> 16) & 0xFF) as u8);
                 initial_data.push(((val >> 24) & 0xFF) as u8);
             }
             driver.copy_to_device(&initial_data, 0).expect("DMA failed");

             let frames = 5;
             
             if json_mode {
                 println!("["); 
             } else {
                 println!("Running {} frames of simulation...", frames);
             }

             for f in 0..frames {
                 match driver.submit_kernel(kernel.clone()) {
                     Ok(_) => {},
                     Err(e) => eprintln!("Frame {} failed: {}", f, e),
                 }

                 // Capture State
                 if json_mode {
                     print!("  {{ \"frame\": {}, \"particles\": [", f);
                     for i in 0..particle_count {
                         let val = driver.memory.read_word((i * 4) as usize).unwrap();
                         print!("{}", val);
                         if i < particle_count - 1 { print!(", "); }
                     }
                     print!("] }}");
                     if f < frames - 1 { println!(","); } else { println!(""); }
                 } else {
                     let val0 = driver.memory.read_word(0).unwrap();
                     println!("Frame {}: P0 Pos = {}", f, val0);
                 }
             }

             if json_mode {
                 println!("]");
             }
        },
        _ => {
            if !json_mode { println!("Unknown command: {}", command); }
        }
    }
}
