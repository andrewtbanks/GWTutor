# GroundWaterTutor - An Interactive Computer Module for Groundwater Education
# Developed by Andy T. Banks and Mary C. Hill
# University of Kansas - Department of Geology 

Communicating the basic principles of groundwater flow and transport to students can be challenging. In this work we present GroundWaterTutor (GWTutor), a freely available interactive computer module for groundwater education.  GWtutor provides a simple, interactive environment for students to learn how key modeling parameters affect hydraulic heads and the flow of tracer particles. Students are presented with options to include the effects of confined and unconfined conditions, heterogeneity, anisotropy, time-discretization, areal recharge and pumping rates, which allows for a wide range of scenarios to be explored. Interactive visualizations illustrate the resulting hydraulic heads, as well as the transport of tracer particles from three origination sites. The software was developed using MATLAB GUI in conjunction with MODFLOW 2005 and MODPATH 6, and is distributed as a set of standalone executables. We provide a sample exercise to accompany GWtutor, which poses students with several tasks; one of which is to find the largest possible pumping rate without extracting too many “contaminant” particles. This exercise also utilizes a free web applet designed to illustrate the effects of urban and agricultural development on groundwater resources [1]. We find that these programs complement each other nicely, and have received positive feedback from students.   
[1]      Hu, Y., Valocchi, A. J., Lindgren, S. A., Ramos, E. A. and Byrd, R. A. (2015), Groundwater Modeling with MODFLOW as a Web Application. Groundwater, 53: 834-835. doi:10.1111/gwat.12372

________________________________________________________________________________________________________________________________
This repository contains the source code along with standalone executables for running GroundWaterTutor on computers with a WINDOWS operating system. 

DOWNLOAD GroundWaterTutor STANDALONE EXECUATBLES

The standalone execuatble for GWTutor is contained in the directory /GWTutor. Download this entire directory to your computer and exectue GWTutor.exe

The Installation process will start automatically. You will need administrative privledges on the computer to install GWTutor (which includes the MATLAB RUNTIME 2017a support library) 

The standalone executable GWTutor.exe requires installation of MATLAB RUNTIME 2017.  This is compiled with GWTutor.exe and will be installed as part of the GWTutor installation process. It is also free to download at https://www.mathworks.com/products/compiler/matlab-runtime.html. 


____________________________________________________________________________________________________________________________________
SOURCE CODE 

Navigate to /GWTutor_Source_Code

GWTutor_INPUT_GUI.m is the main function - execute this to run GWTutor in MATLAB

GWTutor_OUTPUT_GUI.m is a function called in GWTutor_INPUT_GUI.m which runs the MODFLOW and MODPATH models and provides the GUI for visualizing model results. 

The directory /modflow contains the support codes that format user input into MODFLOW 2005 input files

The directory /modpath contains the support codes that format user input into MODPATH 6 input files

The directory /gui_ex1 contains an example of MODPATH and MODFLOW input and output files produced by GWtutor 

The script draw_polys.m is used to generate the polygons representing model cells in the GUI





