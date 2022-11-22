stats_funcs = [ioc, entropy, quadgramlog, orthodot, pioc]
function stats(txt::Txt)
    while true
        println("Choose your function or STOP:")
        display(stats_funcs)
        func = readline()
        if func == "STOP"
            break
        elseif func == "pioc"
            find_period(periodic_ioc.(Ref(txt), 1:20))
        try
            # replace Main with whatever module the functions are defined in
            getfield(Main, Symbol(func))(txt)
        catch e
            @warn "Error running $func", exception = e
        end
    end
end