#Calculate the amount of time a station is empty. Station can be 1 or 2
function calcStationEmptyTime(stats::SimStats, station::Int64)
    localDebug = false
res =0.0
curT = 0.0
empty = false;

if station!=1 & station!=2
     ErrorException("Station needs to be 1 or 2! It currently has value")
end

    for i in 1:size(stats.overview_usage, 1)
        if stats.overview_usage[i,station+1]==0
            if empty #if was already empty
                addedTime = stats.overview_usage[i,1] - stats.overview_usage[i-1,1]
                res += addedTime
            else #if wasn't empty, this is the start of a to be calculated period 
                empty=true;
            end
        elseif empty #the station isn't empty anymore, but it was before. So we add the time between the last two events
                addedTime = stats.overview_usage[i,1] - stats.overview_usage[i-1,1]
                res += addedTime
                empty=false
        end
        if localDebug
        println("Cur entry:  ", stats.overview_usage[i,1], "," , stats.overview_usage[i,station+1], "  empty time: ", res, " station empty: ", empty)
        end
    end
    return res
end