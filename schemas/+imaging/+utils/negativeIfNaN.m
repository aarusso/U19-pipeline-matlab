function x = negativeIfNaN(x)

  x(isnan(x)) = -0.1;
  
end
