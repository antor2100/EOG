%% Spectral Sharpness, slope of power spectrum
function res = spectral_map(img, blk_size, pad_len, use_gpu)
% blk_size = 32; %big block size for more coefficients of the power spectrum
d_blk = blk_size/8; % Distance b/w blocks

pad_L = fliplr(img(:, 1:pad_len)); % Take 16 columns on the left of the
                                    % original image to pad to the left
pad_R = fliplr(img(:, end-pad_len:end));%Take 16 columns on the right of the
                                        % original image to pad to the
                                        % right
img = [pad_L img pad_R]; %Pad left and right

pad_T = flipud(img(1:pad_len, :)); %Similarly, pad top and bottom
pad_B = flipud(img(end-pad_len:end, :));
img = [pad_T; img; pad_B];

num_rows = size(img, 1);
num_cols = size(img, 2);
res = zeros(num_rows, num_cols) - 100;
% contrast_thresold = 0;

disp_progress; % Just to show progress
for r = blk_size/2+1:d_blk:num_rows-blk_size/2 % Just start from inside blocks
                                                % of the padded image
  disp_progress(r, num_rows);
  for c = blk_size/2+1:d_blk:num_cols-blk_size/2
    gry_blk = img(...
      r-blk_size/2:r+blk_size/2-1,...
      c-blk_size/2:c+blk_size/2-1 ...
      );
    % contrastMap = contrast_map_overlap(gry_blk);
    % if(max(contrastMap(:))> contrast_thresold) % Avoid the case when contrast = 0
    if true
      val = blk_amp_spec_slope_eo_vect(gry_blk); % Val(1) will be the slope of
                                                % power spectrum of the block
%       val(1) = 1 - 1 ./ (1 + exp(-3*(val(1) - 2))); %Input to a sigmoid function
      val(1) = 1 - 1 ./ (1 + exp(-3*(val(1) - 2.25))); %Input to a sigmoid function
      %if(max(gry_blk(:))==min(gry_blk(:))) % Black block
       % val_1 = 0;
      %else
        val_1 = val(1);
      %end
    else
        val_1 = 0;
    end
    
    res(...
      r-d_blk/2:r+d_blk/2-1,...
      c-d_blk/2:c+d_blk/2-1 ...
      ) = val_1;
  end
end

% Remove padded parts
res = res(pad_len+1:end-pad_len-1, pad_len+1:end-pad_len-1);
end % function
