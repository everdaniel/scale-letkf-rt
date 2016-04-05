import netCDF4
import datetime
import pytz
import numpy
from os import path
import pytz
from pytz import timezone
import sys
from argparse import ArgumentParser
import numpy as np
from lasagne import layers
from lasagne.nonlinearities import softmax, sigmoid, tanh, linear, rectify
from lasagne.updates import nesterov_momentum, sgd, rmsprop, adam
from lasagne.objectives import squared_error
from lasagne.init import Constant, GlorotUniform, Normal, GlorotNormal, Constant, Uniform
from nolearn.lasagne import NeuralNet
from nolearn.lasagne import TrainSplit
from nolearn.lasagne import BatchIterator
from sklearn.utils import shuffle
from sklearn import preprocessing
from sklearn import linear_model
from matplotlib import pyplot as plt
try:
    from sklearn.model_selection import train_test_split
except ImportError:
    from sklearn.cross_validation import train_test_split



##### Constants 
DIFF = 273.15
DEFAULT_FEATURE_DIR="./features/"
DEFAULT_OUTPUT_DIR="./forecast/"
TEMPLATES=["/data7/gylien/realtime/exp/EastAsia_18km_48p_part1/{}/fcst/mean/history.pe000020.nc",
		   "/data9/gylien/realtime/exp/EastAsia_18km_48p/{}/fcst/mean/history.pe000020.nc"]

def _to_str(dt):
    return dt.strftime("%Y%m%d%H%M%S")

def _to_dt(s):
    dt = datetime.datetime.strptime(s, "%Y%m%d%H%M%S")
    return dt.replace(tzinfo=timezone('UTC'))

def load_feature_db(feature_dir):
    X_data = np.load(path.join(feature-dir, "X_data"))
    y_data = np.load(path.join(feature-dir, "y_data"))
    X_train = X_data.reshape((-1, 14))
    y_train = y_data.reshape((-1, 1))  
    return X_train, y_train

def extract_feature(nc, nc_dt_str):
    X = np.zeros((1, 121, 14))
    inter_data = numpy.zeros((1, 121, 1))
    dataset = netCDF4.Dataset(nc, "r")
    var_time =  dataset.variables["time"]
    var_T, var_U, var_V =  dataset.variables["T"], dataset.variables["U"], dataset.variables["V"]
    since = datetime.datetime(_to_dt(nc_dt_str).year, 1, 1, 0, 0, 0, 0, tzinfo=pytz.utc)
    # Loop 121 times
    for idx2 in range(0, len(var_time)):
        sec = var_time[idx2]
        dt = since + datetime.timedelta(seconds=sec)
        dt_str = _to_str(dt)

        #features
        forecast_time = idx2
        time_of_day = dt.hour
        t1, t2, t3, t4 = var_T[idx2, 0, 37, 0] - DIFF, var_T[idx2, 0, 38, 0] - DIFF, var_T[idx2, 0, 37, 1] - DIFF, var_T[idx2, 0, 38, 1] - DIFF   
        u1, u2, u3, u4 = var_U[idx2, 0, 37, 0], var_U[idx2, 0, 38, 0], var_U[idx2, 0, 37, 1], var_U[idx2, 0, 38, 1]
        v1, v2, v3, v4 = var_V[idx2, 0, 37, 0], var_V[idx2, 0, 38, 0], var_V[idx2, 0, 37, 1], var_V[idx2, 0, 38, 1]
        model_temperture = t1 * 0.804172 + t2 * 0.124810 + t3 * 0.061477 + t4 * 0.009541

        X[0, idx2] = (idx2, time_of_day, t1, t2, t3, t4, u1, u2, u3, u4, v1, v2, v3, v4)
        inter_data[0, idx2] = model_temperture  
    return X, inter_data

def scale(X_train, X_pred):
    scaler = preprocessing.MinMaxScaler(feature_range=(-1, 1))
    X_train_scaled = scaler.fit_transform(X_train)
    X_pred_scaled = scaler.transform(X_pred) 
    return X_train_scaled, X_pred_scaled, scaler
    
def LinRegression(X_train, y_train):
    regr = linear_model.LinearRegression()
    regr.fit(X_train, y_train)
    return regr

def ANN(X_train, y_train, verbose):
    layer_s = [("input", layers.InputLayer),
               ("dense0", layers.DenseLayer),
               ("output", layers.DenseLayer)]

    network = NeuralNet(layers=layer_s,
                     input_shape = (None, X_train.shape[1]),
                     dense0_num_units = 100,
                     dense0_W = Constant(val=1./14.0),
                     #dense0_W = Normal(),
                     #dense0_nonlinearity = tanh,
                     output_num_units = 1,
                     output_nonlinearity = None,
                     regression = True,
                     update = sgd,
                     update_learning_rate=0.001,
                     #update_momentum = 0.9,
                     objective_loss_function = squared_error,
                     batch_iterator_train=BatchIterator(batch_size=121),
                     train_split= TrainSplit(eval_size= 0.1),
                     verbose = 1 if verbose else 0,
                     max_epochs =400)

    network.fit(X_train, y_train)
    return network

def plot_temperture(y_preds, fig_file, plot_title=None):
    assert isinstance(y_preds, list)
    for label, y_pred in y_preds:
        plt.plot(y_pred[:], label = label)
    plt.xlabel('Time')
    plt.xticks(np.array([0, 24, 48, 72, 96, 120]))
    plt.ylabel('T (C)')
    plt.legend(loc='best')
    plt.grid()
    plt.savefig(fig_file)
    #plt.show()
    plt.close()

if __name__ == "__main__":
    parser = ArgumentParser()                       
    parser.add_argument("-t", "--time", dest="nc_dt", required=True,
                        help="Date-time identifier to be forecasted (e.g., 20160131180000).")

    parser.add_argument("-f", "--feature-dir", dest="feature_dir", 
                        help="Directory of feature databse (default is /data9/gulan/ann/features/).")

    parser.add_argument("-o", "--output-dir", dest="output_dir", 
                        help="Directory to save forecast result (default is /data9/gulan/ann/forecast/)")

    parser.add_argument("-q", "--quiet", action="store_false", required=False, dest="verbose", default=True,
                        help="don't print status messages to stdout.")
                        
    # Parse commandline arguments
    args = parser.parse_args()
    verbose = args.verbose
    feature_dir = args.feature_dir if args.feature_dir and path.exists(args.feature_dir) else DEFAULT_FEATURE_DIR
    output_dir = args.output_dir if args.output_dir and path.exists(args.output_dir) else DEFAULT_OUTPUT_DIR
    nc_dt = _to_dt(args.nc_dt)
    nc_dt_str = _to_str(nc_dt)
    nc_file = None

    # Prepare training data and test data
    assert path.exists(output_dir), "ERROR: directory to save forecast result does not exist ({}).".format(feature_dir)
    assert path.exists(feature_dir), "ERROR: directory of feature database does not exist ({}).".format(feature_dir)
    candidates = [t.format(nc_dt_str) for t in TEMPLATES if path.exists(t.format(nc_dt_str))]
    assert len(candidates) == 1, "ERROR: File not found for {}".format(nc_dt_str)
    nc_file = candidates[0]

    X_train_file = path.join(feature_dir, "X_data")
    y_train_file = path.join(feature_dir, "y_data")	
    date_table_file = path.join(feature_dir, "date_table")
    assert path.exists(X_train_file), "ERROR: File not found ({}).".format(X_train_file)
    assert path.exists(y_train_file), "ERROR: File not found ({}).".format(y_train_file)

    X_pred, inter_data = extract_feature(nc_file, nc_dt_str)
    X_train = np.load(X_train_file)
    y_train = np.load(y_train_file)
    #date_table = []
    #with open(date_table_file, "r") as input:
    #    date_table = [x.strip() for x in input.readlines()]

    X_pred = X_pred.reshape((-1, 14))
    inter_data = inter_data.reshape((-1, 1)) 
    X_train = X_train.reshape((-1, 14))
    y_train = y_train.reshape((-1, 1))
    
    X_train, y_train = shuffle(X_train, y_train, random_state=42)

    # Train models
    X_train, X_pred, _ = scale(X_train, X_pred)
    reg = LinRegression(X_train, y_train)
    ann = ANN(X_train, y_train, verbose)

    y_pred_reg = reg.predict(X_pred)
    y_pred_ann = ann.predict(X_pred)

    # Save forecast result
    ann_file = path.join(output_dir, "{}.{}.ann".format(63518, nc_dt_str))
    reg_file = path.join(output_dir, "{}.{}.reg".format(63518, nc_dt_str))
    model_file = path.join(output_dir,"{}.{}.model".format(63518, nc_dt_str))
    fig_file = path.join(output_dir, "{}.{}.png".format(63518, nc_dt_str))
    with open(ann_file, "w") as f1, open(reg_file, "w") as f2, open(model_file, "w") as f3:
        f1.write("\t".join(map(str, y_pred_ann.reshape((-1))[:])))
        f2.write("\t".join(map(str, y_pred_reg.reshape((-1))[:])))
        f3.write("\t".join(map(str, inter_data.reshape((-1))[:])))

    # Plotting
    arr = [("Model", inter_data), ("ANN", y_pred_ann), ("REG", y_pred_reg)]
    plot_temperture(arr, fig_file)


