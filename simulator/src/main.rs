use simulator::driver::AcceleratorDriver;
use simulator::isa::Instruction;
use simulator::kernels;
use std::env;
use std::fs;
use std::io::Write;

fn main() {
    let args: Vec<String> = env::args().collect();
    
    // Command Line Interface
    let mode = if args.len() > 1 { &args[1] } else { "help" };

    let mut driver = AcceleratorDriver::new();

    match mode {
        "particles" => {
             // ... existing particle logic ...
             let frames = if args.len() > 3 && args[2] == "--steps" { 
                 args[3].parse().unwrap_or(10) 
             } else { 10 };
             let json_output = args.contains(&"--json".to_string());

             let kernel = kernels::get_particle_sim_kernel();
             
             // Initial State
             let particles = 10;
             // Init memory... (omitted for brevity, relies on driver defaults in full ver)
             // Actually let's just run simple demo
             // driver.copy_to_device(...)
             
             if !json_output {
                println!("Running Particle Simulation for {} frames...", frames);
             }
             
             for f in 0..frames {
                 let _ = driver.submit_kernel(kernel.clone());
                 if !json_output {
                    println!("Frame {} Complete. Cycles: {}", f, driver.get_perf_stats());
                 }
             }
        },
        "benchmark" => {
            // Simplified Benchmark Mode for Python Script
            let kernel = kernels::get_particle_sim_kernel();
            match driver.submit_kernel(kernel) {
                Ok(stats) => println!("CYCLES:{}", stats.core_cycles),
                Err(e) => eprintln!("Error: {}", e),
            }
        },
        _ => {
            println!("Usage: simulator [particles|benchmark]");
        }
    }
}
