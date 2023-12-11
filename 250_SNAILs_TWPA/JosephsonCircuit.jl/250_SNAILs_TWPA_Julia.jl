using JosephsonCircuits
using Plots

@variables Rleft Rright Cg Lj1 Cj1 Lj2 Cj2 L1 L2 K1 Idc1
circuit = Tuple{String,String,String,Num}[]

# Input Port
push!(circuit,("P$(1)_$(0)","1","0",1))
push!(circuit,("R$(1)_$(0)","1","0",Rleft))
# Entire device simulation
# Number of SNAILs
Nj=250
j=1
for i = 1:Nj  

    # unitary SNAIL description
    # Cg - capacity to GND
    # Lj{m}, Cj{m} describes a Josephson junction
    # Here flux bias is not simulated
    push!(circuit,("C$(j)_$(0)","$(j)","$(0)",Cg))
    push!(circuit,("Lj$(j)_$(j+1)","$(j)","$(j+1)",Lj1))
    push!(circuit,("C$(j)_$(j+1)","$(j)","$(j+1)",Cj1))
    push!(circuit,("Lj$(j+1)_$(j+2)","$(j+1)","$(j+2)",Lj1))
    push!(circuit,("C$(j+1)_$(j+2)","$(j+1)","$(j+2)",Cj1))
    push!(circuit,("Lj$(j+2)_$(j+3)","$(j+2)","$(j+3)",Lj1))
    push!(circuit,("C$(j+2)_$(j+3)","$(j+2)","$(j+3)",Cj1))
    push!(circuit,("Lj$(j)_$(j+4)","$(j)","$(j+4)",Lj2)) 
    push!(circuit,("C$(j)_$(j+4)","$(j)","$(j+4)",Cj2)) 
    push!(circuit, ("L$(j+4)_$(j+3)","$(j+4)","$(j+3)",L1))       
    
    # increment the index
    j=j+3

end

# Output port
push!(circuit,("R$(j)_$(0)","$(j)","$(0)",Rright))
push!(circuit,("P$(j)_$(0)","$(j)","$(0)",2))

# Setting device parameters
circuitdefs = Dict(
    Lj1 => IctoLj(1.47e-6),
    Cj1 => 80.0e-15,
    Lj2 => IctoLj(0.0735e-6),
    Cj2 => 4e-15,
    Cg => 550.0e-15,
    Rleft => 50.0,
    Rright => 50.0,
    Idc1 =-2.5e-6,
    K1 = 1,
    L1 = 0.1e-12
    L2 =1.6e-6
)


# Setting of pump frequency and signal frequency range
wp=2*pi*6.00*1e9
ws=2*pi*(3.5:0.1:10.5)*1e9

# Setting desired numbers of modes
Npumpmodes = 10
Nsignalmodes = 10

# Setting of pump amplitude
Ip=0.6e-6

# Start Simulation
@time rpm = hbsolve(ws,wp,Ip,Nsignalmodes,Npumpmodes,
    circuit,circuitdefs,pumpports=[1]);

# Plot
p1=plot(ws/(2*pi*1e9),
    10*log10.(abs2.(rpm.signal.S[end-Nsignalmodes+rpm.signal.signalindex,rpm.signal.signalindex,:])),
    ylim=(-40,30),label="S21",
    xlabel="Signal Frequency (GHz)",
    legend=:bottomright,
    title="Scattering Parameters",
    ylabel="dB")

plot!(ws/(2*pi*1e9),
    10*log10.(abs2.(rpm.signal.S[rpm.signal.signalindex,end-Nsignalmodes+rpm.signal.signalindex,:])),
    label="S12",
    )

plot!(ws/(2*pi*1e9),
    10*log10.(abs2.(rpm.signal.S[rpm.signal.signalindex,rpm.signal.signalindex,:])),
    label="S11",
    )

plot!(ws/(2*pi*1e9),
    10*log10.(abs2.(rpm.signal.S[end-Nsignalmodes+rpm.signal.signalindex,end-Nsignalmodes+rpm.signal.signalindex,:])),
    label="S22",
    )

p2=plot(ws/(2*pi*1e9),
    rpm.signal.QE[end-Nsignalmodes+rpm.signal.signalindex,rpm.signal.signalindex,:]./rpm.signal.QEideal[end-Nsignalmodes+rpm.signal.signalindex,rpm.signal.signalindex,:],    
    ylim=(0,1.05),
    title="Quantum efficiency",legend=false,
    ylabel="QE/QE_ideal",xlabel="Signal Frequency (GHz)");

p3=plot(ws/(2*pi*1e9),
    10*log10.(abs2.(rpm.signal.S[:,rpm.signal.signalindex,:]')),
    ylim=(-40,30),label="S21",
    xlabel="Signal Frequency (GHz)",
    legend=false,
    title="All idlers",
    ylabel="dB")


p4=plot(ws/(2*pi*1e9),
    1 .- rpm.signal.CM[end-Nsignalmodes+rpm.signal.signalindex,:],    
    legend=false,title="Commutation \n relation error",
    ylabel="Commutation \n relation error",xlabel="Signal Frequency (GHz)");

plot(p1, p2, p3,p4,layout = (2, 2))
