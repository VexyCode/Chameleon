define isBig(int nr) nothing run
    if (nr > 10) run   
        return yes
    end else run
        return no
    end
end

log(isBig(4))
log("\n")
log(isBig(15))