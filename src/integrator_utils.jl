# Carries along the `u` which is an allocation to save when no callbacks
function handle_callbacks!(integrator,eval_sol_fcn)
  discrete_callbacks = integrator.opts.callback.discrete_callbacks
  continuous_callbacks = integrator.opts.callback.continuous_callbacks
  atleast_one_callback = false

  continuous_modified = false
  discrete_modified = false
  saved_in_cb = false
  if !(typeof(continuous_callbacks)<:Tuple{})
    time,upcrossing,event_occured,idx,counter =
              find_first_continuous_callback(integrator,continuous_callbacks...)
    if event_occured
      integrator.event_last_time = idx
      continuous_modified,saved_in_cb = apply_callback!(integrator,continuous_callbacks[idx],time,upcrossing)
    else
      integrator.event_last_time = 0
    end
  end
  if !(typeof(discrete_callbacks)<:Tuple{})
    discrete_modified,saved_in_cb = apply_discrete_callback!(integrator,discrete_callbacks...)
  end
  if !saved_in_cb
    savevalues!(integrator)
  end

  integrator.u_modified = continuous_modified || discrete_modified
end

function DiffEqBase.savevalues!(integrator::ODEInterfaceIntegrator,force_save=false)
  if integrator.opts.save_on
    uType = eltype(integrator.sol.u)

    if integrator.opts.save_everystep || force_save
        push!(integrator.sol.t,integrator.t)
        save_value!(integrator.sol.u,copy(integrator.u),uType,integrator.sizeu)
    end

    while !isempty(integrator.opts.saveat) &&
        integrator.tdir*top(integrator.opts.saveat) < integrator.tdir*integrator.t
        curt = pop!(integrator.opts.saveat)
        tmp = integrator(curt)::Vector{Float64}
        push!(integrator.sol.t,curt)
        save_value!(integrator.sol.u,tmp,uType,integrator.sizeu)
    end
  end
end
